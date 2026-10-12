// Escritura localmente comprobable: no inicia MQTT, Firebase ni carga .env.
import { normalizeMqttEvent } from './mqtt_event_normalizer.js';

export class EventCollisionError extends Error {
  constructor() {
    super('Incompatible event identity or type for an existing seq');
    this.name = 'EventCollisionError';
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
        current?.type !== undefined && current.type !== ev.type) {
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

  // The existing cancellation projection remains in place. Its idempotent
  // recovery and partial-failure handling belong to 2.1c.
  if (ev.type === 'cancel') {
    await db.ref(`events/${deviceId}_${ev.cancels_seq}`).update({
      cancelledBySeq: ev.seq,
      cancelledAt: serverTimestamp,
    });
  }

  return { dedupKey, userId: result.snapshot?.val()?.userId ?? null,
    written: result.committed };
}
