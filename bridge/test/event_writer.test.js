import assert from 'node:assert/strict';
import test from 'node:test';
import { persistEvent } from '../event_writer.js';

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

  ref(path) {
    return {
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

const incident = (type = 'crash') => ({
  id: deviceId, seq: 1, type, severity: 'grave',
  ts: '2026-10-02T12:00:00Z', queued: false,
});
const cancellation = { id: deviceId, seq: 2, type: 'cancel', cancels_seq: 1 };

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
      assert.ok(current.receivedAt > cancelled.receivedAt);
    }
    assert.equal(db.nodes.size, 2);
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
    assert.equal(db.nodes.size, 2);
  });
}

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
  assert.deepEqual(result, { dedupKey: 'SDA-TEST_1', userId: null });
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
  assert.ok(db.writes.every(({ path }) => path.startsWith('events/')));
});
