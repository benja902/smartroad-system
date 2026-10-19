import { ServerValue } from 'firebase-admin/database';

const key = value => typeof value === 'string' && value.trim().length > 0 &&
  value.length <= 256 && !/[.#$\[\]/\x00-\x1f\x7f]/.test(value);
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const time = value => typeof value === 'number' && Number.isFinite(value) && value >= 0;
export class ContactOperationError extends Error {
  constructor(code, status = 409) { super(code); this.code = code; this.status = status; }
}
export function validRelation(value) {
  if (!object(value)) return false;
  if (value.status === 'pending') return value.activeFrom == null && value.revokedAt == null;
  if (value.status === 'active') return time(value.activeFrom) && value.revokedAt == null;
  return value.status === 'revoked' && time(value.revokedAt) &&
    (value.activeFrom == null || time(value.activeFrom));
}
const read = async (db, path) => (await db.ref(path).get()).val();

// No authorization is derived from this repairable discovery index.
export async function syncContactIndex(db, vehicleId, uid) {
  for (let attempt = 0; attempt < 3; attempt++) {
    const [relation, vehicle, profile] = await Promise.all([
      read(db, `vehicleContacts/${vehicleId}/${uid}`), read(db, `vehicles/${vehicleId}`),
      read(db, `users/${uid}`),
    ]);
    if (!object(profile) || !object(vehicle)) throw new ContactOperationError('INCONSISTENT_ASSOCIATION');
    const owner = vehicle.ownerId === uid;
    if (owner && profile.ownerVehicleId !== vehicleId) throw new ContactOperationError('INCONSISTENT_OWNER');
    const desired = owner || (validRelation(relation) && relation.status === 'active') ? true : null;
    await db.ref(`users/${uid}/vehicleIds/${vehicleId}`).set(desired);
    const latest = await read(db, `vehicleContacts/${vehicleId}/${uid}`);
    const latestVehicle = await read(db, `vehicles/${vehicleId}`);
    if (latestVehicle?.ownerId === vehicle.ownerId && JSON.stringify(latest) === JSON.stringify(relation)) return;
  }
  throw new ContactOperationError('INDEX_RETRY_REQUIRED', 503);
}

export async function reconcileContactIndexes(db) {
  const relations = await read(db, 'vehicleContacts') ?? {};
  let failures = 0;
  // Sequential and separate from MQTT callbacks; no root writes or transactions.
  for (const [vehicleId, contacts] of Object.entries(relations)) {
    if (!key(vehicleId) || !object(contacts)) continue;
    for (const uid of Object.keys(contacts)) {
      if (!key(uid)) continue;
      try { await syncContactIndex(db, vehicleId, uid); } catch { failures++; }
    }
  }
  if (failures) throw new ContactOperationError('INDEX_RETRY_REQUIRED', 503);
}

export async function operateContact({ db, uid, action, vehicleId, contactUid,
  administrator = false, scheduleRecovery = () => {} }) {
  if (!key(vehicleId) || !['accept', 'revoke'].includes(action) || (!administrator && !key(uid))) {
    throw new ContactOperationError('INVALID_REQUEST', 400);
  }
  const target = action === 'accept' ? uid : contactUid;
  if (!key(target) || (administrator && action !== 'revoke')) throw new ContactOperationError('INVALID_REQUEST', 400);
  const vehicle = await read(db, `vehicles/${vehicleId}`);
  // Check the caller before looking up another user's profile or relationship.
  if (action === 'revoke' && !administrator && vehicle?.ownerId !== uid) {
    throw new ContactOperationError('FORBIDDEN', 403);
  }
  const profile = await read(db, `users/${target}`);
  if (!object(vehicle) || !object(profile) || !key(vehicle.ownerId) || vehicle.ownerId === target) {
    throw new ContactOperationError('INCONSISTENT_ASSOCIATION');
  }
  const ref = db.ref(`vehicleContacts/${vehicleId}/${target}`);
  // Keep the server-backed relation in the SDK cache during transaction.
  // get() alone does not populate that cache; never seed null with a stale snapshot.
  const keepCache = () => {};
  ref.on('value', keepCache, () => {});
  let result;
  try {
    const previous = (await ref.once('value')).val();
    if (!validRelation(previous)) throw new ContactOperationError('INVALID_RELATION');
    result = await ref.transaction(current => {
    if (!validRelation(current)) return;
    if (action === 'accept') {
      if (current.status === 'revoked') return;
      if (current.status === 'active') return current;
      return { ...current, status: 'active', activeFrom: ServerValue.TIMESTAMP };
    }
    if (current.status === 'revoked') return current;
    return { ...current, status: 'revoked', revokedAt: ServerValue.TIMESTAMP };
  }, undefined, false);
  } finally { ref.off('value', keepCache); }
  if (!result.committed) throw new ContactOperationError('TRANSITION_CONFLICT');
  let indexSynced = false;
  let recoveryRequested = false;
  const requestRecovery = () => {
    if (!recoveryRequested) { recoveryRequested = true; scheduleRecovery(); }
  };
  try {
    // External-route checks cannot be atomic with a relationship-only transaction.
    const latestVehicle = await read(db, `vehicles/${vehicleId}`);
    const authorityStable = latestVehicle?.ownerId === vehicle.ownerId;
    try { await syncContactIndex(db, vehicleId, target); indexSynced = true; }
    catch { requestRecovery(); }
    if (!authorityStable) throw new ContactOperationError('OWNERSHIP_CHANGED_REVIEW_REQUIRED');
    // Return current state, not a historical response after a concurrent revocation.
    const latest = await read(db, `vehicleContacts/${vehicleId}/${target}`);
    if (!validRelation(latest)) throw new ContactOperationError('RELATION_CHANGED');
    return { status: latest.status, activeFrom: latest.activeFrom ?? null,
      revokedAt: latest.revokedAt ?? null, indexSynced,
      transitionCommitted: true, confirmationPending: false };
  } catch (error) {
    // Every failure beyond the commit must retain a recovery request, including reads.
    requestRecovery();
    if (error instanceof ContactOperationError) {
      error.transitionCommitted = true;
      error.indexSynced = false;
      throw error;
    }
    // The transition is durable, but the latest state/index could not be confirmed.
    // Do not expose the old transaction snapshot as the current authorization.
    return { status: null, activeFrom: null, revokedAt: null, indexSynced: false,
      transitionCommitted: true, confirmationPending: true };
  }
}

// Shares the existing bridge timer. A consumed timer during a running pass
// records pending work; completion requests one delayed pass instead of losing it.
export function createContactRecovery({ reconcile, scheduleRecovery, enabled = true }) {
  let running = false;
  let pending = false;
  return async function recoverContacts() {
    if (!enabled) return;
    if (running) { pending = true; return; }
    running = true;
    pending = false;
    try { await reconcile(); }
    catch { pending = true; }
    finally {
      running = false;
      if (pending) { pending = false; scheduleRecovery(); }
    }
  };
}

// Trust only the configured private TCP peer; forwarded headers never establish trust themselves.
export function createContactHandler({ db, auth, health, scheduleRecovery,
  localEmulator = false, realOperations = false, publicHost, trustedProxyIp }) {
  return async (req, res) => {
    const path = req.url?.split('?')[0];
    if (req.method === 'GET' && path === '/') { res.writeHead(health() ? 200 : 503).end(); return; }
    const action = path === '/contacts/accept' ? 'accept' : path === '/contacts/revoke' ? 'revoke' : null;
    const send = (status, body) => res.writeHead(status, {
      'Content-Type': 'application/json', 'Cache-Control': 'no-store',
    }).end(JSON.stringify(body));
    if (!action) { send(404, { code: 'NOT_FOUND' }); return; }
    if (req.method !== 'POST') { send(405, { code: 'METHOD_NOT_ALLOWED' }); return; }
    const loopback = ['127.0.0.1', '::1', '::ffff:127.0.0.1'].includes(req.socket.remoteAddress);
    const peer = req.socket.remoteAddress?.replace(/^::ffff:/, '');
    const proxyHttps = realOperations && trustedProxyIp && peer === trustedProxyIp &&
      publicHost && req.headers.host === publicHost &&
      req.headers['x-forwarded-proto'] === 'https';
    if (!(localEmulator && loopback) && !proxyHttps) { send(503, { code: 'OPERATIONS_DISABLED_OR_INSECURE' }); return; }
    try {
      const match = /^Bearer ([^\s]+)$/.exec(req.headers.authorization ?? '');
      if (!match) throw new ContactOperationError('UNAUTHENTICATED', 401);
      let identity;
      try { identity = await auth.verifyIdToken(match[1], true); }
      catch { throw new ContactOperationError('UNAUTHENTICATED', 401); }
      if (!key(identity.uid)) throw new ContactOperationError('UNAUTHENTICATED', 401);
      if (!/^application\/json(?:;|$)/i.test(req.headers['content-type'] ?? '')) {
        throw new ContactOperationError('INVALID_CONTENT_TYPE', 415);
      }
      let body = ''; let bytes = 0;
      for await (const chunk of req) {
        bytes += Buffer.byteLength(chunk);
        if (bytes > 2048) throw new ContactOperationError('BODY_TOO_LARGE', 413);
        body += chunk;
      }
      let input;
      try { input = JSON.parse(body); } catch { throw new ContactOperationError('INVALID_JSON', 400); }
      const allowed = action === 'accept' ? ['vehicleId'] : ['vehicleId', 'contactUid'];
      if (!object(input) || Object.keys(input).some(k => !allowed.includes(k))) {
        throw new ContactOperationError('INVALID_REQUEST', 400);
      }
      const result = await operateContact({ db, uid: identity.uid, action, ...input, scheduleRecovery });
      send(200, result);
    } catch (error) {
      send(error instanceof ContactOperationError ? error.status : 503,
        { code: error instanceof ContactOperationError ? error.code : 'OPERATION_UNAVAILABLE',
          ...(error?.transitionCommitted === true ? {
            transitionCommitted: true, indexSynced: false, confirmationPending: true,
          } : {}),
        });
    }
  };
}
