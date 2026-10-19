import assert from 'node:assert/strict';
import { before, beforeEach, after, test } from 'node:test';
import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getDatabase } from 'firebase-admin/database';
import { getAuth } from 'firebase-admin/auth';
import { operateContact, syncContactIndex, reconcileContactIndexes, createContactRecovery, createContactHandler } from '../contact_operations.js';
import { persistEvent } from '../event_writer.js';
const project = 'demo-smartroad-contacts';
assert.equal(process.env.GCLOUD_PROJECT, project, 'fictitious project required');
assert.equal(process.env.FIREBASE_DATABASE_EMULATOR_HOST, '127.0.0.1:19000');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:19099');
const app = initializeApp({ credential: { getAccessToken: async () => ({ access_token: 'owner', expires_in: 3600 }) }, projectId: project, databaseURL: `https://${project}-default-rtdb.firebaseio.com` });
const db = getDatabase(app), auth = getAuth(app);
let server, base; const tokens = {};
before(async () => {
  await db.setRules(await readFile(new URL('../../database.rules.json', import.meta.url), 'utf8'));
  for (const uid of ['owner', 'contact', 'stranger']) {
    try { await auth.deleteUser(uid); } catch {}
    await auth.createUser({ uid, email: `${uid}@example.test`, password: 'Fictitious-Password-123' });
    const response = await fetch(`http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fictitious`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: `${uid}@example.test`, password: 'Fictitious-Password-123', returnSecureToken: true }),
    });
    const result = await response.json(); assert.ok(result.idToken, 'emulator token issued'); tokens[uid] = result.idToken;
  }
  server = http.createServer(createContactHandler({ db, auth, health: () => true, localEmulator: true }));
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});
beforeEach(async () => {
  await db.ref().set({ users: { owner: { ownerVehicleId: 'v', vehicleIds: { v: true } }, contact: { name: 'Contact' }, stranger: { name: 'Other' } },
    vehicles: { v: { ownerId: 'owner', deviceId: 'SDA-TEST' } }, vehicleContacts: { v: { contact: { status: 'pending' } } } });
});
after(async () => { if (server) await new Promise(resolve => server.close(resolve)); await deleteApp(app); });
const run = (action, uid = 'contact', extras = {}) => operateContact({ db, uid, action, vehicleId: 'v', contactUid: 'contact', ...extras });
const relation = async () => (await db.ref('vehicleContacts/v/contact').get()).val();
const call = async (action, uid, body, token) => {
  const r = await fetch(`${base}/contacts/${action}`, { method: 'POST', headers: {
    'Content-Type': 'application/json', Authorization: `Bearer ${token ?? tokens[uid]}` }, body: JSON.stringify(body) });
  return { code: r.status, body: await r.json() };
};
test('authenticated acceptance uses token UID; server time and duplicate acceptance are stable', async () => {
  const start = Date.now();
  assert.equal((await call('accept', 'contact', { vehicleId: 'v' })).code, 200);
  const first = await relation(); assert.equal(first.status, 'active'); assert.ok(first.activeFrom >= start - 2000 && first.activeFrom <= Date.now() + 2000);
  await call('accept', 'contact', { vehicleId: 'v' }); assert.deepEqual(await relation(), first);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).val(), true);
});
test('invalid tokens, missing authority and supplied actor/admin flags cannot write', async () => {
  assert.equal((await call('accept', 'contact', { vehicleId: 'v' }, 'invalid-token')).code, 401);
  assert.equal((await call('accept', 'stranger', { vehicleId: 'v' })).code, 409);
  assert.equal((await call('accept', 'stranger', { vehicleId: 'v', uid: 'contact' })).code, 400);
  assert.equal((await call('revoke', 'contact', { vehicleId: 'v', contactUid: 'contact' })).code, 403);
  assert.equal((await call('revoke', 'stranger', { vehicleId: 'v', contactUid: 'contact', administrator: true })).code, 400);
  assert.deepEqual(await relation(), { status: 'pending' });
});
test('owner withdraws pending invitation; revoked terminal and first timestamp stable', async () => {
  const first = await run('revoke', 'owner'); assert.equal(first.status, 'revoked'); assert.equal(typeof first.revokedAt, 'number');
  await assert.rejects(run('accept'), { code: 'TRANSITION_CONFLICT' });
  const duplicate = await run('revoke', 'owner'); assert.equal(duplicate.revokedAt, first.revokedAt);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).exists(), false);
});
test('concurrent acceptance and revocation finish revoked without index authority', async () => {
  await Promise.allSettled([run('accept'), run('revoke', 'owner'), run('accept')]);
  assert.equal((await relation()).status, 'revoked');
  await reconcileContactIndexes(db);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).exists(), false);
  await assert.rejects(run('accept'), { code: 'TRANSITION_CONFLICT' });
});
test('lost response retry does not recreate authorization or move activeFrom', async () => {
  await run('accept'); const first = await relation(); // discard response
  await run('accept'); assert.deepEqual(await relation(), first);
  await run('revoke', 'owner'); await assert.rejects(run('accept'), { code: 'TRANSITION_CONFLICT' });
});
test('partial index failure returns committed status; restart reconciliation repairs it', async () => {
  let scheduled = 0;
  const broken = { ref(path) { const ref = db.ref(path); if (path.startsWith('users/contact/vehicleIds')) return { set: async () => { throw Error('fictitious outage'); } }; return ref; } };
  const result = await run('accept', 'contact', { db: broken, scheduleRecovery: () => scheduled++ });
  assert.equal(result.status, 'active'); assert.equal(result.indexSynced, false); assert.equal(scheduled, 1);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).exists(), false);
  await reconcileContactIndexes(db); await reconcileContactIndexes(db);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).val(), true);
});
test('delayed stale index addition after revocation is detected and removed', async () => {
  await run('accept'); let intercept = true;
  const delayed = { ref(path) { const ref = db.ref(path); if (path === 'users/contact/vehicleIds/v') return {
    async set(value) { if (intercept) { intercept = false; await run('revoke', 'owner'); } await ref.set(value); },
  }; return ref; } };
  await syncContactIndex(delayed, 'v', 'contact');
  assert.equal((await relation()).status, 'revoked');
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).exists(), false);
});
test('restart preserves legitimate owner indexes and repairs revoked contact indexes', async () => {
  await db.ref('vehicleContacts/v').update({ owner: { status: 'revoked', revokedAt: 1 }, contact: { status: 'revoked', revokedAt: 2 } });
  await db.ref('users/contact/vehicleIds/v').set(true);
  await reconcileContactIndexes(db);
  assert.equal((await db.ref('users/owner/vehicleIds/v').get()).val(), true);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).exists(), false);
});
test('parallel MQTT persistence and contact transactions preserve each other', async () => {
  await Promise.all([run('accept'), ...Array.from({ length: 8 }, (_, seq) => persistEvent('SDA-TEST', { id: 'SDA-TEST', seq, type: 'sos' }, {
    db, serverTimestamp: { '.sv': 'timestamp' }, resolveAssociation: async () => ({ userId: 'owner', vehicleId: 'v' }),
  }))]);
  assert.equal(Object.keys((await db.ref('events').get()).val()).length, 8);
  assert.equal((await relation()).status, 'active');
});
test('local rules deny contactIncidents even to active contact with index', async () => {
  await run('accept'); await db.ref('contactIncidents/v/example').set({ type: 'sos' });
  const response = await fetch(`http://127.0.0.1:19000/contactIncidents/v.json?ns=${project}-default-rtdb&auth=${encodeURIComponent(tokens.contact)}`);
  assert.equal(response.status, 401);
});
test('real operations disabled by default; health remains available', async () => {
  const closed = http.createServer(createContactHandler({ db, auth, health: () => true }));
  await new Promise(resolve => closed.listen(0, '127.0.0.1', resolve));
  try {
    const url = `http://127.0.0.1:${closed.address().port}`;
    assert.equal((await fetch(url)).status, 200);
    assert.equal((await fetch(url + '/contacts/accept', { method: 'POST' })).status, 503);
  } finally { await new Promise(resolve => closed.close(resolve)); }
});
test('administrative revocation reuses operation without HTTP admin flag', async () => {
  assert.equal((await run('revoke', undefined, { administrator: true })).status, 'revoked');
});

test('disabled Firebase account token rejected before transition', async () => {
  await auth.updateUser('stranger', { disabled: true });
  try { assert.equal((await call('accept', 'stranger', { vehicleId: 'v' })).code, 401); }
  finally { await auth.updateUser('stranger', { disabled: false }); }
  assert.deepEqual(await relation(), { status: 'pending' });
});
test('active revocation preserves activation and timestamp on retry', async () => {
  const accepted = await run('accept'); const revoked = await run('revoke', 'owner');
  assert.equal(revoked.activeFrom, accepted.activeFrom);
  assert.ok(revoked.revokedAt >= revoked.activeFrom);
  assert.deepEqual(await run('revoke', 'owner'), revoked);
});
test('relation deleted before transaction is not resurrected from earlier read', async () => {
  const ref = db.ref('vehicleContacts/v/contact');
  const raced = { ref(path) {
    if (path !== 'vehicleContacts/v/contact') return db.ref(path);
    return { on: ref.on.bind(ref), off: ref.off.bind(ref), once: ref.once.bind(ref),
      async transaction(...args) { await ref.remove(); return ref.transaction(...args); } };
  } };
  await assert.rejects(run('accept', 'contact', { db: raced }), { code: 'TRANSITION_CONFLICT' });
  assert.equal(await relation(), null);
});
test('ownership change detected after commit is reported and never restores permissions', async () => {
  const ref = db.ref('vehicleContacts/v/contact');
  const raced = { ref(path) {
    if (path !== 'vehicleContacts/v/contact') return db.ref(path);
    return { on: ref.on.bind(ref), off: ref.off.bind(ref), once: ref.once.bind(ref),
      async transaction(...args) { const result = await ref.transaction(...args);
        await db.ref('vehicles/v/ownerId').set('stranger'); return result; } };
  } };
  await assert.rejects(run('revoke', 'owner', { db: raced }), { code: 'OWNERSHIP_CHANGED_REVIEW_REQUIRED' });
  assert.equal((await relation()).status, 'revoked');
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).exists(), false);
});

test('unauthorized revocation never reads the target profile or relation', async () => {
  const reads = [];
  const observed = { ref(path) { reads.push(path); return db.ref(path); } };
  await assert.rejects(run('revoke', 'stranger', { db: observed }), { code: 'FORBIDDEN' });
  assert.deepEqual(reads, ['vehicles/v']);
});

for (const action of ['accept', 'revoke']) {
  test(`recovery fix: ${action} schedules recovery when vehicle read fails after commit`, async () => {
    if (action === 'revoke') await run('accept');
    let reads = 0, scheduled = 0;
    const broken = { ref(path) {
      const ref = db.ref(path);
      if (path !== 'vehicles/v') return ref;
      return { async get() {
        if (++reads === 2) throw Error('transient post-commit read failure');
        return ref.get();
      } };
    } };
    const result = await run(action, action === 'accept' ? 'contact' : 'owner', {
      db: broken, scheduleRecovery: () => scheduled++,
    });
    assert.equal(scheduled, 1);
    assert.equal(result.transitionCommitted, true);
    assert.equal(result.confirmationPending, true);
    assert.equal(result.indexSynced, false);
    assert.equal(result.status, null, 'a committed snapshot must not masquerade as current state');
    const committed = await relation();
    assert.equal(committed.status, action === 'accept' ? 'active' : 'revoked');
    const index = db.ref('users/contact/vehicleIds/v');
    assert.equal((await index.get()).exists(), action === 'revoke', 'index not yet synchronized');
    await reconcileContactIndexes(db);
    assert.equal((await index.get()).exists(), action === 'accept');
    assert.deepEqual(await relation(), committed, 'repair does not rewrite relationship or timestamps');
    assert.equal((await db.ref('users/owner/vehicleIds/v').get()).val(), true);
  });
}

test('recovery fix: last confirmation read failure retains commit and schedules repair', async () => {
  let reads = 0, scheduled = 0;
  const broken = { ref(path) {
    const ref = db.ref(path);
    if (path !== 'vehicleContacts/v/contact') return ref;
    return { on: ref.on.bind(ref), off: ref.off.bind(ref), once: ref.once.bind(ref),
      transaction: ref.transaction.bind(ref), async get() {
        if (++reads === 3) throw Error('transient confirmation read failure');
        return ref.get();
      } };
  } };
  const result = await run('accept', 'contact', { db: broken, scheduleRecovery: () => scheduled++ });
  assert.equal(scheduled, 1); assert.equal(result.transitionCommitted, true);
  assert.equal(result.confirmationPending, true); assert.equal(result.status, null);
  const committed = await relation();
  await reconcileContactIndexes(db);
  assert.deepEqual(await relation(), committed);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).val(), true);
});

test('recovery fix: a consumed recovery request during reconciliation repairs an already processed relation', async () => {
  let release; const held = new Promise(resolve => { release = resolve; });
  let reached; const processed = new Promise(resolve => { reached = resolve; });
  let passes = 0, active = 0, maxActive = 0, timer;
  const schedule = () => { timer ??= () => recover(); };
  const recover = createContactRecovery({ scheduleRecovery: schedule, reconcile: async () => {
    active++; maxActive = Math.max(maxActive, active);
    try {
      passes++;
      await reconcileContactIndexes(db);
      if (passes === 1) { reached(); await held; }
    } finally { active--; }
  } });
  const first = recover(); await processed; // pending contact already scanned
  const broken = { ref(path) { const ref = db.ref(path);
    return path === 'users/contact/vehicleIds/v' ? { set: async () => { throw Error('transient index failure'); } } : ref;
  } };
  const result = await run('accept', 'contact', { db: broken, scheduleRecovery: schedule });
  assert.equal(result.indexSynced, false); const committed = await relation();
  const consumed = timer; timer = undefined;
  await consumed(); // existing timer fires while the first pass is still running
  await Promise.all(Array.from({ length: 8 }, () => recover()));
  assert.equal(passes, 1); assert.equal(maxActive, 1);
  // Recovery must not block an independent MQTT writer.
  await persistEvent('SDA-TEST', { id: 'SDA-TEST', seq: 50, type: 'sos' }, {
    db, serverTimestamp: { '.sv': 'timestamp' },
    resolveAssociation: async () => ({ userId: 'owner', vehicleId: 'v' }),
  });
  release(); await first;
  assert.equal(typeof timer, 'function', 'consumed request must be scheduled again');
  const followup = timer; timer = undefined; await followup();
  assert.equal(passes, 2); assert.equal(maxActive, 1); assert.equal(timer, undefined);
  assert.equal((await db.ref('users/contact/vehicleIds/v').get()).val(), true);
  assert.equal((await db.ref('users/owner/vehicleIds/v').get()).val(), true);
  assert.deepEqual(await relation(), committed);
  assert.equal((await db.ref('events/SDA-TEST_50').get()).val().type, 'sos');
});

test('recovery fix: HTTP reports a committed transition with pending confirmation', async () => {
  let reads = 0, scheduled = 0;
  const broken = { ref(path) { const ref = db.ref(path);
    return path === 'vehicles/v' ? { async get() {
      if (++reads === 2) throw Error('transient post-commit read'); return ref.get();
    } } : ref;
  } };
  const pendingServer = http.createServer(createContactHandler({
    db: broken, auth, health: () => true, localEmulator: true, scheduleRecovery: () => scheduled++,
  }));
  await new Promise(resolve => pendingServer.listen(0, '127.0.0.1', resolve));
  try {
    const response = await fetch(`http://127.0.0.1:${pendingServer.address().port}/contacts/accept`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tokens.contact}` },
      body: JSON.stringify({ vehicleId: 'v' }),
    });
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.transitionCommitted, true); assert.equal(body.confirmationPending, true);
    assert.equal(body.status, null); assert.equal(body.indexSynced, false); assert.equal(scheduled, 1);
    assert.equal((await relation()).status, 'active');
  } finally { await new Promise(resolve => pendingServer.close(resolve)); }
});
