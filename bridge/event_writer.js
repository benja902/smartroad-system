// Escritura localmente comprobable: no inicia MQTT, Firebase ni carga .env.
import { isUsableEventKey, normalizeMqttEvent } from './mqtt_event_normalizer.js';

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

async function projectCancellation(db, deviceId, cancelRow) {
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
    if (next.cancelledBySeq === undefined) {
      next.cancelledBySeq = seq;
      changed = true;
    }
    if (next.cancelledAt === undefined) {
      next.cancelledAt = receivedAt;
      changed = true;
    }
    if (!changed) {
      outcome = 'duplicate';
      return undefined;
    }
    outcome = 'projected';
    return next;
  }, undefined, false);
  if (!result.committed && outcome === 'conflict') throw new CancellationConflictError();
  if (!result.committed && outcome !== 'duplicate') {
    throw new Error('Cancellation projection did not commit');
  }
  return result.committed;
}

// A restart scans the existing events node once. For the MVP's single SDA this
// avoids a new queue; a failed scan/projection is retried by the caller.
export async function reconcileStoredCancellations(db, { reportDiagnostic } = {}) {
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
      if (await projectCancellation(db, row.id, row)) projected++;
    } catch (error) {
      if (!(error instanceof CancellationConflictError)) throw error;
      reportDiagnostic?.('CONFLICTING_CANCELLATION');
    }
  }
  return { scanned: cancellations.length, projected };
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
  db, resolveAssociation, serverTimestamp, kind, reportDiagnostic,
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
    } else if (!changed) {
      outcome = 'duplicate';
      return undefined;
    }
    outcome = 'written';
    return next;
  }, undefined, false);

  if (!result.committed && outcome === 'collision') throw new EventCollisionError();
  if (!result.committed && outcome !== 'duplicate') {
    throw new Error('Event transaction did not commit');
  }
  if (kind !== 'diagnostic' && !association) reportDiagnostic?.('NO_ASSOCIATION');
  if (conflicts.size) reportDiagnostic?.('CONFLICTING_FIELD');

  let projected = false;
  if (ev.type === 'cancel') {
    try {
      // ServerValue.TIMESTAMP in a transaction snapshot may be a local
      // estimate. Read the committed row before copying its first receipt.
      const cancelRow = (await ref.get()).val();
      projected = await projectCancellation(db, deviceId, cancelRow);
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
