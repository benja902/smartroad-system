// Escritura localmente comprobable: no inicia MQTT, Firebase ni carga .env.
import { isUsableEventKey, normalizeMqttEvent } from './mqtt_event_normalizer.js';
import { createHash } from 'node:crypto';

export class EventCollisionError extends Error {
  constructor() {
    super('Incompatible event identity or type for an existing seq');
    this.name = 'EventCollisionError';
  }
}

export class CancellationConflictError extends Error {
  constructor() {
    super('An incompatible cancellation is already recorded');
    this.name = 'CancellationConflictError';
  }
}

export class CancellationProjectionError extends Error {
  constructor(cause) {
    super('Cancellation row persisted but projection failed', { cause });
    this.name = 'CancellationProjectionError';
  }
}

function isRecord(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function criticalIndexFields(row) {
  if (row.cancelledBySeq !== undefined || row.queued === true ||
      !(row.type === 'sos' ||
        (['crash', 'rollover'].includes(row.type) && row.severity === 'grave'))) {
    return {};
  }
  if (typeof row.vehicleId === 'string' && row.vehicleId) {
    return { criticalVehicleId: row.vehicleId };
  }
  if (typeof row.userId === 'string' && row.userId) {
    return { criticalLegacyUserId: row.userId };
  }
  return {};
}

function applyCriticalIndexFields(row) {
  const desired = criticalIndexFields(row);
  let changed = false;
  for (const field of ['criticalVehicleId', 'criticalLegacyUserId']) {
    if (desired[field] === undefined && row[field] !== undefined) {
      delete row[field];
      changed = true;
    } else if (desired[field] !== undefined && row[field] !== desired[field]) {
      row[field] = desired[field];
      changed = true;
    }
  }
  return changed;
}

function readIndexPaths(key, row) {
  if (typeof row.type !== 'string') return [];
  // Historical records without receivedAt are retained at the start of the
  // index. This does not assert a time for the original event.
  const time = String(Number.isFinite(row.receivedAt)
    ? Math.max(0, Math.trunc(row.receivedAt)) : 0).padStart(16, '0');
  const identity = createHash('sha256').update(key).digest('hex');
  const suffix = `${time}_${identity}`;
  const paths = [];
  if (typeof row.userId === 'string' && row.userId) {
    paths.push(`eventReadIndex/users/${row.userId}/${suffix}`);
  }
  if (typeof row.vehicleId === 'string' && row.vehicleId) {
    paths.push(`eventReadIndex/vehicles/${row.vehicleId}/${suffix}`);
  }
  return paths;
}

async function syncReadIndex(db, key, row) {
  const paths = readIndexPaths(key, row);
  if (!paths.length) return false;
  const digest = createHash('sha256').update(JSON.stringify(row)).digest('hex');
  let changed = false;
  for (const path of paths) {
    const result = await db.ref(path).transaction((current) =>
      current?.eventKey === key && current?.digest === digest
        ? undefined : { eventKey: key, digest }, undefined, false);
    changed = result.committed || changed;
  }
  return changed;
}

// Recreate missing pointers and refresh changed rows after a bridge restart.
export async function reconcileChronologicalReadIndex(db) {
  const rows = (await db.ref('events').get()).val() ?? {};
  let updated = 0;
  for (const [key, row] of Object.entries(rows)) {
    if (!isRecord(row) || !isUsableEventKey(row.id, row.seq) ||
        key !== `${row.id}_${row.seq}`) continue;
    if (await syncReadIndex(db, key, row)) updated++;
  }
  return { scanned: Object.keys(rows).length, updated };
}

function addCompatibleFields(target, incoming, conflicts, path = '') {
  let changed = false;
  for (const [key, value] of Object.entries(incoming)) {
    if (value === null || value === undefined) continue;
    const field = path ? `${path}.${key}` : key;
    if (target[key] === null || target[key] === undefined) {
      target[key] = value;
      changed = true;
    } else if (key === 'queued' && value === true && target[key] === false) {
      target[key] = true;
      changed = true;
    } else if (isRecord(target[key]) && isRecord(value)) {
      changed = addCompatibleFields(target[key], value, conflicts, field) || changed;
    } else if (target[key] !== value) {
      // Distinct ts values do not establish a seq collision. Keep first value.
      conflicts.add(field);
    }
  }
  return changed;
}

async function projectCancellation(db, deviceId, cancelRow, serverTimestamp) {
  const { seq, cancels_seq: originalSeq, receivedAt } = cancelRow;
  if (!Number.isFinite(receivedAt)) {
    throw new Error('Cancellation row has no valid first receipt');
  }
  const ref = db.ref(`events/${deviceId}_${originalSeq}`);
  let outcome;
  const result = await ref.transaction((current) => {
    if (current !== null && (!isRecord(current) ||
        current.id !== undefined && current.id !== deviceId ||
        current.seq !== undefined && current.seq !== originalSeq ||
        current.cancelledBySeq !== undefined && current.cancelledBySeq !== seq)) {
      outcome = 'conflict';
      return undefined;
    }
    const next = current ? structuredClone(current) : {};
    let changed = false;
    let cancellationChanged = false;
    if (next.cancelledBySeq === undefined) {
      next.cancelledBySeq = seq;
      changed = true;
      cancellationChanged = true;
    }
    if (next.cancelledAt === undefined) {
      next.cancelledAt = receivedAt;
      changed = true;
      cancellationChanged = true;
    }
    changed = applyCriticalIndexFields(next) || changed;
    if (!changed) {
      outcome = 'duplicate';
      return undefined;
    }
    if (current?.type !== undefined && cancellationChanged && serverTimestamp !== undefined) {
      next.updatedAt = serverTimestamp;
    }
    outcome = 'projected';
    return next;
  }, undefined, false);
  if (!result.committed && outcome === 'conflict') throw new CancellationConflictError();
  if (!result.committed && outcome !== 'duplicate') {
    throw new Error('Cancellation projection did not commit');
  }
  if (result.committed) await syncReadIndex(db, `${deviceId}_${originalSeq}`, (await ref.get()).val());
  return result.committed;
}

// A restart scans the existing events node once. For the MVP's single SDA this
// avoids a new queue; a failed scan/projection is retried by the caller.
export async function reconcileStoredCancellations(db, { reportDiagnostic, serverTimestamp } = {}) {
  const rows = (await db.ref('events').get()).val() ?? {};
  const cancellations = Object.entries(rows)
    .filter(([, row]) => isRecord(row) && row.type === 'cancel')
    .sort((a, b) => (a[1].receivedAt ?? Infinity) - (b[1].receivedAt ?? Infinity));
  let projected = 0;
  for (const [key, row] of cancellations) {
    if (!isUsableEventKey(row.id, row.seq) ||
        !isUsableEventKey(row.id, row.cancels_seq) ||
        row.cancels_seq === row.seq || key !== `${row.id}_${row.seq}` ||
        !Number.isFinite(row.receivedAt)) {
      reportDiagnostic?.('INVALID_STORED_CANCEL');
      continue;
    }
    try {
      if (await projectCancellation(db, row.id, row, serverTimestamp)) projected++;
    } catch (error) {
      if (!(error instanceof CancellationConflictError)) throw error;
      reportDiagnostic?.('CONFLICTING_CANCELLATION');
    }
  }
  return { scanned: cancellations.length, projected };
}

// Rebuild the small read index from canonical rows after a restart. Historical
// rows without vehicleId keep their owner-only path; no event is migrated.
export async function reconcileCriticalReadIndex(db) {
  const rows = (await db.ref('events').get()).val() ?? {};
  let updated = 0;
  for (const [key, row] of Object.entries(rows)) {
    if (!isRecord(row) || !isUsableEventKey(row.id, row.seq) ||
        key !== `${row.id}_${row.seq}`) continue;
    const desired = criticalIndexFields(row);
    if (row.criticalVehicleId === desired.criticalVehicleId &&
        row.criticalLegacyUserId === desired.criticalLegacyUserId) continue;
    const ref = db.ref(`events/${key}`);
    const result = await ref.transaction((current) => {
      // Admin SDK may invoke the callback with null before loading the
      // committed row; the server then retries against the actual value.
      const next = structuredClone(current ?? row);
      return applyCriticalIndexFields(next) ? next : undefined;
    }, undefined, false);
    if (result.committed) updated++;
  }
  return { scanned: Object.keys(rows).length, updated };
}

export async function ingestMqttEvent(topic, payload, options) {
  const normalized = normalizeMqttEvent(topic, payload, {
    prefix: options.prefix ?? 'sda', optionalBlockPolicy: 'drop',
  });
  const result = await persistEvent(normalized.deviceId, normalized.event, {
    ...options, kind: normalized.kind,
  });
  for (const code of normalized.diagnostics ?? []) options.reportDiagnostic?.(code);
  if (normalized.kind === 'diagnostic') options.reportDiagnostic?.('UNKNOWN_TYPE');
  return result;
}

export async function persistEvent(deviceId, ev, {
  db, resolveAssociation, serverTimestamp, kind, reportDiagnostic, scheduleRecovery,
}) {
  if (!isUsableEventKey(deviceId, ev.seq) || ev.id !== deviceId ||
      ev.type === 'cancel' && (!isUsableEventKey(deviceId, ev.cancels_seq) ||
        ev.cancels_seq === ev.seq)) {
    throw new Error('Event identity or cancellation reference cannot form a safe key');
  }
  // Unknown types are retained only as unassociated diagnostics. Current
  // owner/contact queries require userId or vehicleId, so they remain hidden.
  const association = kind === 'diagnostic' ? null : await resolveAssociation(deviceId);
  const userId = association?.userId ?? null;
  const dedupKey = `${deviceId}_${ev.seq}`;
  const ref = db.ref(`events/${dedupKey}`);
  const firmwareFields = { ...ev };
  for (const field of [
    'vehicleId', 'userId', 'acknowledged', 'cancelledBySeq', 'cancelledAt',
    'receivedAt', 'updatedAt', 'status', 'notifiedAt',
    'criticalVehicleId', 'criticalLegacyUserId',
    'eventReadIndex',
  ]) delete firmwareFields[field];

  let outcome;
  let conflicts = new Set();
  const result = await ref.transaction((current) => {
    conflicts = new Set();
    if (current !== null && !isRecord(current) ||
        current?.id !== undefined && current.id !== deviceId ||
        current?.seq !== undefined && current.seq !== ev.seq ||
        current?.type !== undefined && current.type !== ev.type ||
        ev.type === 'cancel' && current?.cancels_seq !== undefined &&
          current.cancels_seq !== ev.cancels_seq) {
      outcome = 'collision';
      return undefined;
    }

    const next = current ? structuredClone(current) : {};
    const changed = addCompatibleFields(next, firmwareFields, conflicts);
    if (!current) {
      next.receivedAt = serverTimestamp;
      if (kind !== 'diagnostic') {
        if (userId) next.userId = userId;
        if (association?.vehicleId) next.vehicleId = association.vehicleId;
      }
    } else if (current.type === undefined && ev.type !== undefined &&
               current.receivedAt === undefined) {
      // An early-cancel placeholder is not the original's first receipt.
      next.receivedAt = serverTimestamp;
      if (kind !== 'diagnostic') {
        if (userId && next.userId === undefined) next.userId = userId;
        if (association?.vehicleId && next.vehicleId === undefined) {
          next.vehicleId = association.vehicleId;
        }
      }
    }
    const indexChanged = applyCriticalIndexFields(next);
    if (current && !changed && !indexChanged) {
      outcome = 'duplicate';
      return undefined;
    }
    if (current?.type !== undefined && changed) next.updatedAt = serverTimestamp;
    outcome = 'written';
    return next;
  }, undefined, false);

  if (!result.committed && outcome === 'collision') throw new EventCollisionError();
  if (!result.committed && outcome !== 'duplicate') {
    throw new Error('Event transaction did not commit');
  }
  if (kind !== 'diagnostic' && !association) reportDiagnostic?.('NO_ASSOCIATION');
  if (conflicts.size) reportDiagnostic?.('CONFLICTING_FIELD');

  // The canonical row is committed first. Reuse the bridge's bounded recovery
  // timer if its owner pointer cannot be written; keep the failure visible.
  try {
    await syncReadIndex(db, dedupKey, (await ref.get()).val());
  } catch (error) {
    scheduleRecovery?.();
    throw error;
  }

  let projected = false;
  if (ev.type === 'cancel') {
    try {
      // ServerValue.TIMESTAMP in a transaction snapshot may be a local
      // estimate. Read the committed row before copying its first receipt.
      const cancelRow = (await ref.get()).val();
      projected = await projectCancellation(db, deviceId, cancelRow, serverTimestamp);
    } catch (error) {
      if (error instanceof CancellationConflictError) {
        reportDiagnostic?.('CONFLICTING_CANCELLATION');
        throw error;
      }
      throw new CancellationProjectionError(error);
    }
  }

  return { dedupKey, userId: result.snapshot?.val()?.userId ?? null,
    written: result.committed || projected };
}
