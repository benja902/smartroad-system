import assert from 'node:assert/strict';
import test from 'node:test';
import {
  CancellationConflictError, CancellationProjectionError, EventCollisionError,
  ingestMqttEvent, persistEvent, reconcileStoredCancellations,
  reconcileCriticalReadIndex,
  reconcileChronologicalReadIndex,
} from '../event_writer.js';
import { MAX_MQTT_EVENT_BYTES, MqttEventValidationError } from '../mqtt_event_normalizer.js';

const deviceId = 'SDA-TEST';
const eventPath = 'events/SDA-TEST_1';
const serverTimestamp = Object.freeze({ '.sv': 'timestamp' });
const options = { timeout: 5000 };

// Doble local de update(): fusiona campos, elimina valores null y resuelve
// el marcador de tiempo. No usa el SDK, red, .env ni credenciales.
class MemoryDatabase {
  nodes = new Map();
  writes = [];
  clock = 1000;
  failProjectionOnce = false;
  failUserIndexOnce = false;

  ref(path) {
    return {
      transaction: async (update) => {
        if (this.failUserIndexOnce && path.startsWith('eventReadIndex/users/')) {
          this.failUserIndexOnce = false;
          throw new Error('simulated owner index failure');
        }
        if (this.failProjectionOnce && path === eventPath) {
          this.failProjectionOnce = false;
          throw new Error('simulated projection failure');
        }
        const current = structuredClone(this.nodes.get(path) ?? null);
        const next = update(current);
        if (next === undefined) {
          return { committed: false, snapshot: { val: () => this.read(path) } };
        }
        const now = ++this.clock;
        const committed = structuredClone(next);
        if (committed.receivedAt?.['.sv'] === 'timestamp') committed.receivedAt = now;
        if (committed.updatedAt?.['.sv'] === 'timestamp') committed.updatedAt = now;
        this.writes.push({ path, patch: structuredClone(next) });
        this.nodes.set(path, committed);
        return { committed: true, snapshot: { val: () => this.read(path) } };
      },
      update: async (patch) => {
        this.writes.push({ path, patch: structuredClone(patch) });
        const current = structuredClone(this.nodes.get(path) ?? {});
        const now = ++this.clock;
        for (const [key, value] of Object.entries(patch)) {
          if (value === null) delete current[key];
          else current[key] = value?.['.sv'] === 'timestamp'
            ? now : structuredClone(value);
        }
        this.nodes.set(path, current);
      },
      get: async () => ({
        val: () => this.nodes.has(path) ? this.read(path) : Object.fromEntries(
          [...this.nodes]
            .filter(([key]) => key.startsWith(`${path}/`))
            .map(([key, value]) => [key.slice(path.length + 1), structuredClone(value)])),
      }),
    };
  }

  read(path) {
    return structuredClone(this.nodes.get(path));
  }
}

function fixture(association = { userId: 'owner-test', vehicleId: 'vehicle-test' }) {
  const db = new MemoryDatabase();
  const resolvedIds = [];
  const write = (ev) => persistEvent(deviceId, ev, {
    db,
    serverTimestamp,
    resolveAssociation: async (id) => {
      resolvedIds.push(id);
      return association;
    },
  });
  return { db, write, resolvedIds };
}

const eventCount = (db) => [...db.nodes.keys()]
  .filter((path) => path.startsWith('events/')).length;

const incident = (type = 'crash') => ({
  id: deviceId, seq: 1, type, severity: 'grave',
  ts: '2026-10-02T12:00:00Z', queued: false,
});
const cancellation = { id: deviceId, seq: 2, type: 'cancel', cancels_seq: 1 };

test('critical read index follows canonical state, never MQTT administrative fields', options, async () => {
  const { db, write } = fixture();
  await write({ ...incident(), criticalVehicleId: 'forged' });
  assert.equal(db.read(eventPath).criticalVehicleId, 'vehicle-test');
  assert.equal(db.read(eventPath).criticalLegacyUserId, undefined);
  await write(cancellation);
  assert.equal(db.read(eventPath).criticalVehicleId, undefined);
  await write(incident());
  assert.equal(db.read(eventPath).criticalVehicleId, undefined);
});

test('critical read index excludes queued, noncritical and unassociated events', options, async () => {
  for (const event of [
    { ...incident(), queued: true },
    { ...incident(), severity: 'moderado' },
    { ...incident(), type: 'future_alarm' },
  ]) {
    const { db, write } = fixture();
    await write(event);
    assert.equal(db.read(eventPath).criticalVehicleId, undefined);
  }
  const { db, write } = fixture(null);
  await write(incident());
  assert.equal(db.read(eventPath).criticalVehicleId, undefined);
});

test('chronological pointers order by first receipt and refresh on cancellation only', options, async () => {
  const { db, write } = fixture();
  await write({ ...incident(), seq: 9 });
  await write({ ...incident(), seq: 10 });
  const prefix = 'eventReadIndex/vehicles/vehicle-test/';
  const pointers = [...db.nodes.entries()].filter(([path]) => path.startsWith(prefix));
  assert.equal(pointers.length, 2);
  assert.equal([...db.nodes.keys()].filter((path) =>
    path.startsWith('eventReadIndex/users/owner-test/')).length, 2);
  assert.equal(pointers.map(([path]) => path).sort()[1], pointers[1][0]);
  assert.deepEqual(pointers.map(([, pointer]) => pointer.eventKey), ['SDA-TEST_9', 'SDA-TEST_10']);
  const beforeCancel = db.read(pointers[0][0]);
  await write({ id: deviceId, seq: 11, type: 'cancel', cancels_seq: 9 });
  assert.notEqual(db.read(pointers[0][0]).digest, beforeCancel.digest);
  const writes = db.writes.length;
  await write({ id: deviceId, seq: 11, type: 'cancel', cancels_seq: 9 });
  assert.equal(db.writes.length, writes);
});

test('restart backfills historical owner pointer and skips unassociated rows', options, async () => {
  const db = new MemoryDatabase();
  db.nodes.set('events/SDA-TEST_1', {
    id: deviceId, seq: 1, type: 'crash', userId: 'owner-test',
  });
  db.nodes.set('events/SDA-TEST_2', {
    id: deviceId, seq: 2, type: 'crash', receivedAt: 200,
  });
  assert.deepEqual(await reconcileChronologicalReadIndex(db), { scanned: 2, updated: 1 });
  assert.deepEqual(await reconcileChronologicalReadIndex(db), { scanned: 2, updated: 0 });
  const paths = [...db.nodes.keys()].filter((path) => path.startsWith('eventReadIndex/'));
  assert.equal(paths.length, 1);
  assert.match(paths[0], /^eventReadIndex\/users\/owner-test\/0{16}_/);
});

test('failed owner pointer schedules recovery during the same bridge run', options, async () => {
  const db = new MemoryDatabase();
  db.failUserIndexOnce = true;
  let scheduledRecovery;
  let schedules = 0;
  await assert.rejects(ingestMqttEvent('sda/SDA-TEST/event', JSON.stringify(incident()), {
    db, serverTimestamp,
    resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
    scheduleRecovery: () => {
      schedules++;
      scheduledRecovery = () => reconcileChronologicalReadIndex(db);
    },
  }), /simulated owner index failure/);
  assert.equal(schedules, 1);
  assert.equal(db.read(eventPath).criticalVehicleId, 'vehicle-test');
  assert.equal([...db.nodes.keys()].some((path) =>
    path.startsWith('eventReadIndex/users/owner-test/')), false);
  assert.deepEqual(await scheduledRecovery(), { scanned: 1, updated: 1 });
  const userPointers = [...db.nodes.entries()].filter(([path]) =>
    path.startsWith('eventReadIndex/users/owner-test/'));
  assert.equal(userPointers.length, 1);
  assert.equal(userPointers[0][1].eventKey, 'SDA-TEST_1');
  assert.deepEqual(await scheduledRecovery(), { scanned: 1, updated: 0 });
});

test('restart reconciliation restores historical critical index idempotently', options, async () => {
  const db = new MemoryDatabase();
  db.nodes.set('events/SDA-TEST_1', {
    id: deviceId, seq: 1, type: 'sos', userId: 'owner-test', receivedAt: 100,
  });
  db.nodes.set('events/SDA-TEST_2', {
    id: deviceId, seq: 2, type: 'crash', severity: 'grave',
    vehicleId: 'vehicle-test', userId: 'owner-test', receivedAt: 200,
  });
  db.nodes.set('events/SDA-TEST_3', {
    id: deviceId, seq: 3, type: 'crash', severity: 'grave',
    vehicleId: 'vehicle-test', userId: 'owner-test', cancelledBySeq: 4,
    criticalVehicleId: 'vehicle-test', receivedAt: 300,
  });
  assert.deepEqual(await reconcileCriticalReadIndex(db), { scanned: 3, updated: 3 });
  assert.equal(db.read('events/SDA-TEST_1').criticalLegacyUserId, 'owner-test');
  assert.equal(db.read('events/SDA-TEST_2').criticalVehicleId, 'vehicle-test');
  assert.equal(db.read('events/SDA-TEST_3').criticalVehicleId, undefined);
  assert.deepEqual(await reconcileCriticalReadIndex(db), { scanned: 3, updated: 0 });
});

for (const type of ['crash', 'rollover', 'sos']) {
  test(`${type}: incident -> cancel -> retransmissions preserve cancellation`, options, async () => {
    const { db, write } = fixture();
    const original = incident(type);
    await write(original);
    await write(cancellation);
    const cancelled = db.read(eventPath);
    assert.equal(cancelled.cancelledBySeq, 2);
    const withoutTs = { ...original };
    delete withoutTs.ts;
    for (const delivery of [original, { ...original, ts: '2026-10-02T13:00:00Z' }, withoutTs]) {
      await write(delivery);
      const current = db.read(eventPath);
      assert.equal(current.cancelledBySeq, cancelled.cancelledBySeq);
      assert.equal(current.cancelledAt, cancelled.cancelledAt);
      assert.equal(current.type, type);
      assert.equal(current.receivedAt, cancelled.receivedAt);
    }
    assert.equal(eventCount(db), 2);
    assert.equal(db.read('events/SDA-TEST_2').cancels_seq, 1);
  });

  test(`${type}: cancel -> original preserves the early cancellation`, options, async () => {
    const { db, write } = fixture();
    await write(cancellation);
    const placeholder = db.read(eventPath);
    assert.equal(placeholder.type, undefined);
    assert.equal(placeholder.cancelledBySeq, 2);
    await write(incident(type));
    await write({ ...incident(type), ts: null });
    const current = db.read(eventPath);
    assert.equal(current.type, type);
    assert.equal(current.seq, 1);
    assert.equal(current.cancelledBySeq, placeholder.cancelledBySeq);
    assert.equal(current.cancelledAt, placeholder.cancelledAt);
    assert.equal(current.userId, 'owner-test');
    assert.equal(current.vehicleId, 'vehicle-test');
    assert.equal(eventCount(db), 2);
  });
}

test('C01/C03: later cancel keeps its row and first cancelledAt after duplicate deliveries', options, async () => {
  const { db, write } = fixture();
  await write(incident());
  await write(cancellation);
  const cancelRow = db.read('events/SDA-TEST_2');
  const original = db.read(eventPath);
  assert.equal(original.cancelledAt, cancelRow.receivedAt);
  assert.equal(original.cancelledBySeq, 2);
  assert.equal(original.receivedAt, 1001);
  const duplicate = await write(cancellation);
  assert.equal(duplicate.written, false);
  assert.deepEqual(db.read('events/SDA-TEST_2'), cancelRow);
  assert.deepEqual(db.read(eventPath), original);
});

test('C02: early cancel has no original receivedAt and completion does not reactivate it', options, async () => {
  const { db, write } = fixture();
  await write(cancellation);
  const cancelRow = db.read('events/SDA-TEST_2');
  const placeholder = db.read(eventPath);
  assert.equal(placeholder.receivedAt, undefined);
  assert.equal(placeholder.cancelledAt, cancelRow.receivedAt);
  await write(incident());
  const completed = db.read(eventPath);
  assert.equal(completed.cancelledAt, cancelRow.receivedAt);
  assert.equal(completed.cancelledBySeq, 2);
  assert.ok(completed.receivedAt > cancelRow.receivedAt);
  assert.equal(completed.type, 'crash');
  assert.equal(completed.status, undefined);
});

test('C04: concurrent incompatible cancellations retain the first projection and both rows', options, async () => {
  const { db, write } = fixture();
  await write(incident());
  const other = { ...cancellation, seq: 3 };
  const results = await Promise.allSettled([write(cancellation), write(other)]);
  assert.equal(results.filter(({ status }) => status === 'fulfilled').length, 1);
  assert.equal(results.filter(({ reason }) => reason instanceof CancellationConflictError).length, 1);
  assert.equal(db.read(eventPath).cancelledBySeq, 2);
  assert.equal(db.read(eventPath).cancelledAt, db.read('events/SDA-TEST_2').receivedAt);
  assert.equal(db.read('events/SDA-TEST_3').type, 'cancel');
});

test('C04: a reused cancel seq cannot change its original reference', options, async () => {
  const { db, write } = fixture();
  await write(cancellation);
  const firstRow = db.read('events/SDA-TEST_2');
  const firstOriginal = db.read(eventPath);
  await assert.rejects(write({ ...cancellation, cancels_seq: 4 }), EventCollisionError);
  assert.deepEqual(db.read('events/SDA-TEST_2'), firstRow);
  assert.deepEqual(db.read(eventPath), firstOriginal);
  assert.equal(db.read('events/SDA-TEST_4'), undefined);
});

test('C05: failed projection is visible; restart scan repairs it once without moving dates', options, async () => {
  const { db, write } = fixture();
  await write(incident());
  db.failProjectionOnce = true;
  await assert.rejects(write(cancellation), CancellationProjectionError);
  const cancelRow = db.read('events/SDA-TEST_2');
  assert.equal(cancelRow.type, 'cancel');
  assert.equal(db.read(eventPath).cancelledAt, undefined);
  const first = await reconcileStoredCancellations(db);
  assert.deepEqual(first, { scanned: 1, projected: 1 });
  const repaired = db.read(eventPath);
  assert.equal(repaired.cancelledAt, cancelRow.receivedAt);
  assert.equal(repaired.cancelledBySeq, 2);
  assert.deepEqual(await reconcileStoredCancellations(db), { scanned: 1, projected: 0 });
  assert.deepEqual(db.read(eventPath), repaired);
});

test('C05: duplicate cancel delivery also repairs a partial write', options, async () => {
  const { db, write } = fixture();
  db.failProjectionOnce = true;
  await assert.rejects(write(cancellation), CancellationProjectionError);
  const cancelRow = db.read('events/SDA-TEST_2');
  const retried = await write(cancellation);
  assert.equal(retried.written, true);
  assert.equal(db.read(eventPath).cancelledAt, cancelRow.receivedAt);
  assert.equal(db.read(eventPath).receivedAt, undefined);
  assert.deepEqual(db.read('events/SDA-TEST_2'), cancelRow);
});

test('C05: recovery skips a stored cancel with an unsafe RTDB identifier', options, async () => {
  const { db } = fixture();
  db.nodes.set('events/SDA.TEST_2', {
    id: 'SDA.TEST', seq: 2, type: 'cancel', cancels_seq: 1, receivedAt: 1001,
  });
  const diagnostics = [];
  assert.deepEqual(await reconcileStoredCancellations(db, {
    reportDiagnostic: (code) => diagnostics.push(code),
  }), { scanned: 1, projected: 0 });
  assert.deepEqual(diagnostics, ['INVALID_STORED_CANCEL']);
  assert.equal(db.read('events/SDA.TEST_1'), undefined);
});

test('C05: direct persistence uses the same event-key restriction', options, async () => {
  const { db } = fixture();
  const context = {
    db, serverTimestamp,
    resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
  };
  await assert.rejects(persistEvent('SDA.TEST', {
    id: 'SDA.TEST', seq: 2, type: 'cancel', cancels_seq: 1,
  }, context), /safe key/);
  await assert.rejects(persistEvent('SDA-TEST', {
    id: 'OTHER', seq: 2, type: 'cancel', cancels_seq: 1,
  }, context), /safe key/);
  assert.equal(db.writes.length, 0);
});

for (const acknowledged of [true, false]) {
  test(`historical acknowledged=${acknowledged} survives payload and timestamp changes`, options, async () => {
    const { db, write } = fixture();
    db.nodes.set(eventPath, { ...incident(), acknowledged });
    await write({ ...incident(), ts: 0, acknowledged: !acknowledged });
    await write({ ...incident(), ts: null, acknowledged: null });
    assert.equal(db.read(eventPath).acknowledged, acknowledged);
    for (const { patch } of db.writes) {
      assert.ok(!Object.hasOwn(patch, 'acknowledged'));
    }
  });
}

test('payload cannot supply application state and is not mutated', options, async () => {
  const { db, write } = fixture();
  const payload = Object.freeze({
    ...incident(), acknowledged: true, cancelledBySeq: 99,
    cancelledAt: null, vehicleId: 'untrusted-vehicle', userId: 'untrusted-user',
  });
  await write(payload);
  const stored = db.read(eventPath);
  for (const field of ['acknowledged', 'cancelledBySeq', 'cancelledAt']) {
    assert.ok(!Object.hasOwn(stored, field));
    assert.ok(!Object.hasOwn(db.writes[0].patch, field));
    assert.ok(Object.hasOwn(payload, field));
  }
  assert.equal(stored.vehicleId, 'vehicle-test');
  assert.equal(stored.userId, 'owner-test');
  assert.equal(payload.vehicleId, 'untrusted-vehicle');
});

test('null or false cancellation fields in a retransmission cannot clear stored evidence', options, async () => {
  const { db, write } = fixture();
  await write(incident());
  await write(cancellation);
  const before = db.read(eventPath);
  await write({ ...incident(), cancelledBySeq: null, cancelledAt: false });
  const after = db.read(eventPath);
  assert.equal(after.cancelledBySeq, before.cancelledBySeq);
  assert.equal(after.cancelledAt, before.cancelledAt);
});

test('missing association never accepts vehicleId from the MQTT payload', options, async () => {
  const { db, write, resolvedIds } = fixture(null);
  const result = await write({ ...incident(), vehicleId: 'untrusted-vehicle' });
  assert.deepEqual(result, { dedupKey: 'SDA-TEST_1', userId: null, written: true });
  assert.deepEqual(resolvedIds, [deviceId]);
  assert.ok(!Object.hasOwn(db.read(eventPath), 'vehicleId'));
  assert.ok(!Object.hasOwn(db.read(eventPath), 'userId'));
});

test('ingestion does not modify personal state or write outside events', options, async () => {
  const { db, write } = fixture();
  const path = 'userIncidentState/owner-test/SDA-TEST_1';
  const personal = { acknowledged: true };
  db.nodes.set(path, personal);
  await write(incident());
  await write(cancellation);
  await write({ ...incident(), ts: '2026-10-02T14:00:00Z', acknowledged: false });
  assert.deepEqual(db.read(path), personal);
  assert.ok(db.writes.every(({ path }) =>
    path.startsWith('events/') || path.startsWith('eventReadIndex/')));
});

test('A01: MQTT integration writes one associated row and strips injected backend state', options, async () => {
  const { db } = fixture();
  const result = await ingestMqttEvent('sda/SDA-TEST/event', JSON.stringify({
    ...incident(), vehicleId: 'injected', userId: 'injected', acknowledged: true,
  }), {
    db, resolveAssociation: async () => ({ vehicleId: 'vehicle-test', userId: 'owner-test' }),
    serverTimestamp,
  });
  assert.equal(result.written, true);
  assert.equal(eventCount(db), 1);
  assert.equal(db.read(eventPath).receivedAt, 1001);
  assert.equal(db.read(eventPath).vehicleId, 'vehicle-test');
  assert.equal(db.read(eventPath).userId, 'owner-test');
  assert.equal(db.read(eventPath).acknowledged, undefined);
});

test('A02–A04/C06: invalid required data cannot reach persistence; partial event can', options, async () => {
  const { db } = fixture();
  let associationReads = 0;
  const context = { db, resolveAssociation: async () => {
    associationReads++;
    return null;
  }, serverTimestamp };
  for (const [topic, payload] of [
    ['sda/SDA-TEST/event', '{'],
    ['sda/SDA-TEST/event', Buffer.alloc(MAX_MQTT_EVENT_BYTES + 1, 0x78)],
    ['sda/SDA-TEST/event', JSON.stringify({ id: 'OTHER', seq: 1, type: 'sos' })],
    ['sda/SDA+TEST/event', JSON.stringify({ id: 'SDA+TEST', seq: 1, type: 'sos' })],
    ['sda/SDA-TEST/event', JSON.stringify({ id: deviceId, seq: '1', type: 'sos' })],
    ['sda/SDA-TEST/event', JSON.stringify({ id: deviceId, seq: 1 })],
    ['sda/SDA-TEST/event', JSON.stringify({ id: deviceId, seq: 2, type: 'cancel' })],
  ]) {
    await assert.rejects(ingestMqttEvent(topic, payload, context), MqttEventValidationError);
  }
  assert.equal(db.writes.length, 0);
  assert.equal(associationReads, 0);
  await ingestMqttEvent('sda/SDA-TEST/event', JSON.stringify({
    id: deviceId, seq: 1, type: 'rollover',
  }), context);
  assert.equal(db.read(eventPath).type, 'rollover');
  assert.equal(db.read(eventPath).position, undefined);
  assert.equal(db.read(eventPath).ts, undefined);
});

test('approved optional-block policy keeps incident, drops only invalid blocks and reports fixed codes', options, async () => {
  const { db } = fixture();
  const diagnostics = [];
  await ingestMqttEvent('sda/SDA-TEST/event', JSON.stringify({
    ...incident(), position: { fix: true, lat: 91, lon: 1 },
    detection: { peak_g: 'bad' }, device: { battery_v: 4.02 },
  }), {
    db, resolveAssociation: async () => ({ vehicleId: 'vehicle-test', userId: 'owner-test' }),
    serverTimestamp, reportDiagnostic: (code) => diagnostics.push(code),
  });
  assert.deepEqual(diagnostics, ['INVALID_OPTIONAL_DETECTION', 'INVALID_OPTIONAL_POSITION']);
  assert.equal(db.read(eventPath).type, 'crash');
  assert.equal(db.read(eventPath).position, undefined);
  assert.equal(db.read(eventPath).detection, undefined);
  assert.deepEqual(db.read(eventPath).device, { battery_v: 4.02 });
});

test('A05/A06: unknown and unassociated events remain invisible to owner queries', options, async () => {
  const { db } = fixture();
  const diagnostics = [];
  let lookups = 0;
  const resolveAssociation = async () => { lookups++; return null; };
  await ingestMqttEvent('sda/SDA-TEST/event', JSON.stringify({
    ...incident(), type: 'future_alarm', severity: 'grave',
  }), { db, resolveAssociation, serverTimestamp,
    reportDiagnostic: (code) => diagnostics.push(code) });
  assert.equal(lookups, 0);
  assert.deepEqual(diagnostics, ['UNKNOWN_TYPE']);
  assert.equal(db.read(eventPath).type, 'future_alarm');
  assert.equal(db.read(eventPath).vehicleId, undefined);
  assert.equal(db.read(eventPath).userId, undefined);
  await ingestMqttEvent('sda/SDA-TEST/event', JSON.stringify({
    ...incident(), seq: 2, vehicleId: 'injected',
  }), { db, resolveAssociation, serverTimestamp,
    reportDiagnostic: (code) => diagnostics.push(code) });
  assert.equal(db.read('events/SDA-TEST_2').userId, undefined);
  assert.equal(db.read('events/SDA-TEST_2').vehicleId, undefined);
  assert.deepEqual(diagnostics, ['UNKNOWN_TYPE', 'NO_ASSOCIATION']);
});

test('A07: failed association lookup propagates and cannot be treated as absent', options, async () => {
  const { db } = fixture();
  let failLookup = true;
  const context = {
    db, serverTimestamp,
    resolveAssociation: async () => {
      if (failLookup) throw new Error('temporary lookup failure');
      return { userId: 'owner-test', vehicleId: 'vehicle-test' };
    },
  };
  await assert.rejects(persistEvent(deviceId, incident(), context), /temporary lookup failure/);
  assert.equal(db.nodes.size, 0);
  failLookup = false;
  await persistEvent(deviceId, incident(), context);
  assert.equal(db.read(eventPath).userId, 'owner-test');
});

test('B01/B02: duplicates and changed ts do not replace first receipt or earlier evidence', options, async () => {
  const { db, write } = fixture();
  await write(incident());
  const first = db.read(eventPath);
  const writes = db.writes.length;
  const duplicate = await write(incident());
  assert.equal(duplicate.written, false);
  assert.equal(db.writes.length, writes);
  await write({ ...incident(), ts: '2026-10-02T13:00:00Z' });
  await write({ ...incident(), ts: null });
  assert.equal(db.read(eventPath).receivedAt, first.receivedAt);
  assert.equal(db.read(eventPath).ts, first.ts);
  assert.equal(db.read(eventPath).updatedAt, undefined);
  assert.equal(eventCount(db), 1);
});

test('material enrichment sets updatedAt without changing first receipt or state', options, async () => {
  const { db, write } = fixture();
  await write({ id: deviceId, seq: 1, type: 'crash' });
  const first = db.read(eventPath);
  assert.equal(first.updatedAt, undefined);
  await write({ id: deviceId, seq: 1, type: 'crash', queued: true,
    position: { lat: -9.9, lon: -76.2 } });
  const enriched = db.read(eventPath);
  assert.equal(enriched.receivedAt, first.receivedAt);
  assert.ok(enriched.updatedAt > first.receivedAt);
  assert.equal(enriched.queued, true);
  await write({ id: deviceId, seq: 1, type: 'crash', queued: true,
    position: { lat: -9.9, lon: -76.2 } });
  assert.deepEqual(db.read(eventPath), enriched);
  await write({ id: deviceId, seq: 2, type: 'cancel', cancels_seq: 1 });
  const cancelled = db.read(eventPath);
  assert.equal(cancelled.receivedAt, first.receivedAt);
  assert.equal(cancelled.cancelledBySeq, 2);
  assert.ok(cancelled.updatedAt > enriched.updatedAt);
  await write({ id: deviceId, seq: 2, type: 'cancel', cancels_seq: 1 });
  assert.deepEqual(db.read(eventPath), cancelled);
});

test('B03/B04/H01: compatible additions preserve history and reject destructive null', options, async () => {
  const { db, write } = fixture();
  db.nodes.set(eventPath, {
    id: deviceId, seq: 1, type: 'crash', userId: 'legacy-owner',
    acknowledged: true, cancelledBySeq: 2, cancelledAt: 800,
    receivedAt: 700, detection: { peak_g: 10 },
  });
  await write({ ...incident(), detection: { peak_g: null, duration_ms: 62 },
    position: { lat: -9.9, lon: -76.2 }, acknowledged: false,
    cancelledBySeq: null, cancelledAt: null,
  });
  const current = db.read(eventPath);
  assert.equal(current.receivedAt, 700);
  assert.equal(current.userId, 'legacy-owner');
  assert.equal(current.vehicleId, undefined);
  assert.equal(current.acknowledged, true);
  assert.equal(current.cancelledBySeq, 2);
  assert.equal(current.cancelledAt, 800);
  assert.deepEqual(current.detection, { peak_g: 10, duration_ms: 62 });
  assert.deepEqual(current.position, { lat: -9.9, lon: -76.2 });
});

test('B05: same seq with incompatible type is rejected without changing existing row', options, async () => {
  const { db, write } = fixture();
  await write(incident());
  const first = db.read(eventPath);
  await assert.rejects(write({ ...incident(), type: 'sos' }), EventCollisionError);
  assert.deepEqual(db.read(eventPath), first);
});

test('B05/B06: concurrent incompatible types leave the first committed row intact', options, async () => {
  const { db, write } = fixture();
  const outcomes = await Promise.allSettled([
    write(incident('crash')),
    write(incident('sos')),
  ]);
  assert.equal(outcomes.filter((item) => item.status === 'fulfilled').length, 1);
  assert.equal(outcomes.filter((item) => item.reason instanceof EventCollisionError).length, 1);
  assert.equal(eventCount(db), 1);
  assert.equal(db.read(eventPath).receivedAt, 1001);
});

test('compatible retransmission keeps first metrics and reports conflict without payload values', options, async () => {
  const { db } = fixture();
  const diagnostics = [];
  const context = {
    db, serverTimestamp,
    resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
    reportDiagnostic: (code) => diagnostics.push(code),
  };
  await persistEvent(deviceId, { ...incident(), detection: { peak_g: 10 } }, context);
  await persistEvent(deviceId, {
    ...incident(), detection: { peak_g: 20, duration_ms: 62 },
  }, context);
  assert.deepEqual(db.read(eventPath).detection, { peak_g: 10, duration_ms: 62 });
  assert.deepEqual(diagnostics, ['CONFLICTING_FIELD']);
});

test('B06: concurrent duplicate deliveries keep one key and first receipt', options, async () => {
  const { db, write } = fixture();
  const outcomes = await Promise.all([write(incident()), write(incident())]);
  assert.equal(outcomes.filter((item) => item.written).length, 1);
  assert.equal(eventCount(db), 1);
  assert.equal(db.read(eventPath).receivedAt, 1001);
});

test('B07: queued true survives a later copy with queued absent or false', options, async () => {
  const { db, write } = fixture();
  await write({ id: deviceId, seq: 1, type: 'crash', queued: true });
  await write({ id: deviceId, seq: 1, type: 'crash' });
  await write({ id: deviceId, seq: 1, type: 'crash', queued: false });
  assert.equal(db.read(eventPath).queued, true);
  assert.equal(db.read(eventPath).ts, undefined);
  assert.equal(db.read(eventPath).position, undefined);
});
