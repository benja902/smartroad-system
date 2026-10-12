import assert from 'node:assert/strict';
import test from 'node:test';
import {
  CancellationConflictError, CancellationProjectionError, ingestMqttEvent, persistEvent,
  reconcileStoredCancellations, reconcileCriticalReadIndex,
  reconcileChronologicalReadIndex,
} from '../event_writer.js';
import { AssociationLookupError, resolveAssociation } from '../association_resolver.js';

const emulatorOnly = process.env.FIREBASE_DATABASE_EMULATOR_HOST === '127.0.0.1:19000' &&
  process.env.GCLOUD_PROJECT === 'demo-smartroad-bridge';

test('Database Emulator: chronological pointers survive restart and track cancellation', {
  skip: emulatorOnly ? false : 'requires local RTDB Emulator and demo project',
  timeout: 30000,
}, async () => {
  const { initializeApp, deleteApp } = await import('firebase-admin/app');
  const { getDatabase, ServerValue } = await import('firebase-admin/database');
  const app = initializeApp({
    projectId: 'demo-smartroad-bridge',
    databaseURL: 'https://demo-smartroad-bridge-default-rtdb.firebaseio.com',
  }, `chronological-index-${Date.now()}`);
  try {
    const db = getDatabase(app);
    await db.ref('events').remove();
    await db.ref('eventReadIndex').remove();
    const context = {
      db, serverTimestamp: ServerValue.TIMESTAMP,
      resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
    };
    await persistEvent('SDA-TEST', { id: 'SDA-TEST', seq: 9, type: 'crash' }, context);
    await persistEvent('SDA-TEST', { id: 'SDA-TEST', seq: 10, type: 'crash' }, context);
    const index = db.ref('eventReadIndex/vehicles/vehicle-test');
    const pointers = (await index.orderByKey().limitToLast(2).get()).val();
    assert.deepEqual(Object.values(pointers).map(({ eventKey }) => eventKey),
      ['SDA-TEST_9', 'SDA-TEST_10']);
    await index.remove();
    assert.deepEqual(await reconcileChronologicalReadIndex(db), { scanned: 2, updated: 2 });
    assert.deepEqual(await reconcileChronologicalReadIndex(db), { scanned: 2, updated: 0 });
    const firstKey = Object.keys((await index.get()).val())[0];
    const digest = (await index.child(firstKey).get()).val().digest;
    await persistEvent('SDA-TEST', {
      id: 'SDA-TEST', seq: 11, type: 'cancel', cancels_seq: 9,
    }, context);
    assert.notEqual((await index.child(firstKey).get()).val().digest, digest);
    assert.equal((await db.ref('events/SDA-TEST_9').get()).val().cancelledBySeq, 11);
    await db.ref('events').remove();
    await db.ref('eventReadIndex').remove();
  } finally {
    await deleteApp(app);
  }
});

test('Database Emulator: critical index survives restart and clears with cancellation', {
  skip: emulatorOnly ? false : 'requires local RTDB Emulator and demo project',
  timeout: 30000,
}, async () => {
  const { initializeApp, deleteApp } = await import('firebase-admin/app');
  const { getDatabase, ServerValue } = await import('firebase-admin/database');
  const app = initializeApp({
    projectId: 'demo-smartroad-bridge',
    databaseURL: 'https://demo-smartroad-bridge-default-rtdb.firebaseio.com',
  }, `critical-index-${Date.now()}`);
  try {
    const db = getDatabase(app);
    const ref = db.ref('events/SDA-TEST_1');
    await db.ref('events').remove();
    const context = {
      db, serverTimestamp: ServerValue.TIMESTAMP,
      resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
    };
    await persistEvent('SDA-TEST', {
      id: 'SDA-TEST', seq: 1, type: 'crash', severity: 'grave',
    }, context);
    assert.equal((await ref.get()).val().criticalVehicleId, 'vehicle-test');
    await ref.child('criticalVehicleId').remove();
    assert.equal((await ref.get()).val().criticalVehicleId, undefined);
    assert.deepEqual(await reconcileCriticalReadIndex(db), { scanned: 1, updated: 1 });
    assert.deepEqual(await reconcileCriticalReadIndex(db), { scanned: 1, updated: 0 });
    await persistEvent('SDA-TEST', {
      id: 'SDA-TEST', seq: 2, type: 'cancel', cancels_seq: 1,
    }, context);
    assert.equal((await ref.get()).val().criticalVehicleId, undefined);
    assert.deepEqual(await reconcileCriticalReadIndex(db), { scanned: 2, updated: 0 });
    await db.ref('events').remove();
  } finally {
    await deleteApp(app);
  }
});

test('Database Emulator: transaction keeps first receipt and compatible enrichment', {
  skip: emulatorOnly ? false : 'requires local RTDB Emulator and demo project',
  timeout: 30000,
}, async () => {
  const { initializeApp, deleteApp } = await import('firebase-admin/app');
  const { getDatabase, ServerValue } = await import('firebase-admin/database');
  const app = initializeApp({
    projectId: 'demo-smartroad-bridge',
    databaseURL: 'https://demo-smartroad-bridge-default-rtdb.firebaseio.com',
  }, `test-${Date.now()}`);
  try {
    const db = getDatabase(app);
    const path = 'events/SDA-TEST_1';
    const ref = db.ref(path);
    await ref.remove();
    const context = {
      db, serverTimestamp: ServerValue.TIMESTAMP,
      resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
    };
    const original = { id: 'SDA-TEST', seq: 1, type: 'crash' };
    const results = await Promise.all([
      persistEvent('SDA-TEST', original, context),
      persistEvent('SDA-TEST', original, context),
    ]);
    assert.equal(results.filter((result) => result.written).length, 1);
    const first = (await ref.get()).val();
    assert.equal(typeof first.receivedAt, 'number');
    assert.equal(first.userId, 'owner-test');
    await persistEvent('SDA-TEST', {
      ...original, position: { lat: -9.9, lon: -76.2 },
    }, context);
    const enriched = (await ref.get()).val();
    assert.equal(enriched.receivedAt, first.receivedAt);
    assert.deepEqual(enriched.position, { lat: -9.9, lon: -76.2 });
    await ref.remove();
  } finally {
    await deleteApp(app);
  }
});

test('Database Emulator: two vehicles with one deviceId cannot attribute an event', {
  skip: emulatorOnly ? false : 'requires local RTDB Emulator and demo project',
  timeout: 30000,
}, async () => {
  const { initializeApp, deleteApp } = await import('firebase-admin/app');
  const { getDatabase, ServerValue } = await import('firebase-admin/database');
  const app = initializeApp({
    projectId: 'demo-smartroad-bridge',
    databaseURL: 'https://demo-smartroad-bridge-default-rtdb.firebaseio.com',
  }, `association-test-${Date.now()}`);
  try {
    const db = getDatabase(app);
    await db.ref('vehicles').set({
      'vehicle-test-a': { deviceId: 'SDA-TEST', ownerId: 'owner-a' },
      'vehicle-test-b': { deviceId: 'SDA-TEST', ownerId: 'owner-b' },
    });
    await assert.rejects(resolveAssociation(db, 'SDA-TEST'),
      (error) => error instanceof AssociationLookupError &&
        error.code === 'AMBIGUOUS_ASSOCIATION');
    await assert.rejects(persistEvent('SDA-TEST', {
      id: 'SDA-TEST', seq: 9, type: 'crash',
    }, {
      db, serverTimestamp: ServerValue.TIMESTAMP,
      resolveAssociation: (id) => resolveAssociation(db, id),
    }), (error) => error instanceof AssociationLookupError &&
      error.code === 'AMBIGUOUS_ASSOCIATION');
    assert.equal((await db.ref('events/SDA-TEST_9').get()).exists(), false);
    await db.ref('vehicles').remove();
  } finally {
    await deleteApp(app);
  }
});

test('Database Emulator C02–C04: early and concurrent cancels keep one first projection', {
  skip: emulatorOnly ? false : 'requires local RTDB Emulator and demo project',
  timeout: 30000,
}, async () => {
  const { initializeApp, deleteApp } = await import('firebase-admin/app');
  const { getDatabase, ServerValue } = await import('firebase-admin/database');
  const app = initializeApp({
    projectId: 'demo-smartroad-bridge',
    databaseURL: 'https://demo-smartroad-bridge-default-rtdb.firebaseio.com',
  }, `cancel-test-${Date.now()}`);
  try {
    const db = getDatabase(app);
    const root = db.ref('events');
    await root.remove();
    const context = {
      db, serverTimestamp: ServerValue.TIMESTAMP,
      resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
    };
    const cancel = (seq) => ({ id: 'SDA-TEST', seq, type: 'cancel', cancels_seq: 1 });
    const outcomes = await Promise.allSettled([
      persistEvent('SDA-TEST', cancel(2), context),
      persistEvent('SDA-TEST', cancel(3), context),
    ]);
    assert.equal(outcomes.filter(({ status }) => status === 'fulfilled').length, 1);
    assert.equal(outcomes.filter(({ reason }) => reason instanceof CancellationConflictError).length, 1);
    const placeholder = (await db.ref('events/SDA-TEST_1').get()).val();
    const winningSeq = placeholder.cancelledBySeq;
    const firstCancel = (await db.ref(`events/SDA-TEST_${winningSeq}`).get()).val();
    assert.equal(placeholder.cancelledAt, firstCancel.receivedAt);
    assert.equal(placeholder.receivedAt, undefined);
    await persistEvent('SDA-TEST', cancel(winningSeq), context);
    assert.deepEqual((await db.ref('events/SDA-TEST_1').get()).val(), placeholder);
    await persistEvent('SDA-TEST', { id: 'SDA-TEST', seq: 1, type: 'crash' }, context);
    const completed = (await db.ref('events/SDA-TEST_1').get()).val();
    assert.equal(completed.cancelledAt, firstCancel.receivedAt);
    assert.equal(completed.cancelledBySeq, winningSeq);
    assert.equal(typeof completed.receivedAt, 'number');
    await root.remove();
  } finally {
    await deleteApp(app);
  }
});

test('Database Emulator C05: saved cancel survives projection failure and restart reconciliation', {
  skip: emulatorOnly ? false : 'requires local RTDB Emulator and demo project',
  timeout: 30000,
}, async () => {
  const { initializeApp, deleteApp } = await import('firebase-admin/app');
  const { getDatabase, ServerValue } = await import('firebase-admin/database');
  const app = initializeApp({
    projectId: 'demo-smartroad-bridge',
    databaseURL: 'https://demo-smartroad-bridge-default-rtdb.firebaseio.com',
  }, `recovery-test-${Date.now()}`);
  try {
    const db = getDatabase(app);
    const root = db.ref('events');
    await root.remove();
    let failOnce = true;
    const failingDb = {
      ref: (path) => {
        const real = db.ref(path);
        return path !== 'events/SDA-TEST_1' ? real : {
          transaction: async (...args) => {
            if (failOnce) {
              failOnce = false;
              throw new Error('simulated RTDB failure');
            }
            return real.transaction(...args);
          },
        };
      },
    };
    const context = {
      db: failingDb, serverTimestamp: ServerValue.TIMESTAMP,
      resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
    };
    await assert.rejects(persistEvent('SDA-TEST', {
      id: 'SDA-TEST', seq: 2, type: 'cancel', cancels_seq: 1,
    }, context), CancellationProjectionError);
    const cancelRow = (await db.ref('events/SDA-TEST_2').get()).val();
    assert.equal(cancelRow.type, 'cancel');
    assert.equal((await db.ref('events/SDA-TEST_1').get()).exists(), false);
    assert.deepEqual(await reconcileStoredCancellations(db), { scanned: 1, projected: 1 });
    const original = (await db.ref('events/SDA-TEST_1').get()).val();
    assert.equal(original.cancelledAt, cancelRow.receivedAt);
    assert.deepEqual(await reconcileStoredCancellations(db), { scanned: 1, projected: 0 });
    assert.deepEqual((await db.ref('events/SDA-TEST_1').get()).val(), original);
    await root.remove();
  } finally {
    await deleteApp(app);
  }
});

test('Database Emulator C05: colon, dash and underscore IDs recover after partial cancellation', {
  skip: emulatorOnly ? false : 'requires local RTDB Emulator and demo project',
  timeout: 30000,
}, async () => {
  const { initializeApp, deleteApp } = await import('firebase-admin/app');
  const { getDatabase, ServerValue } = await import('firebase-admin/database');
  const app = initializeApp({
    projectId: 'demo-smartroad-bridge',
    databaseURL: 'https://demo-smartroad-bridge-default-rtdb.firebaseio.com',
  }, `identity-recovery-test-${Date.now()}`);
  try {
    const db = getDatabase(app);
    const root = db.ref('events');
    for (const id of ['SDA:TEST', 'SDA-TEST', 'SDA_TEST']) {
      await root.remove();
      const originalPath = `events/${id}_1`;
      let failOnce = true;
      const failingDb = {
        ref: (path) => {
          const real = db.ref(path);
          return path !== originalPath ? real : {
            transaction: (...args) => {
              if (failOnce) {
                failOnce = false;
                throw new Error('simulated projection failure');
              }
              return real.transaction(...args);
            },
          };
        },
      };
      const topic = `sda/${id}/event`;
      const cancel = JSON.stringify({ id, seq: 2, type: 'cancel', cancels_seq: 1 });
      const options = {
        db: failingDb, serverTimestamp: ServerValue.TIMESTAMP,
        resolveAssociation: async () => ({ userId: 'owner-test', vehicleId: 'vehicle-test' }),
      };
      await assert.rejects(ingestMqttEvent(topic, cancel, options), CancellationProjectionError);
      const cancelRow = (await db.ref(`events/${id}_2`).get()).val();
      assert.equal(cancelRow.type, 'cancel');
      assert.equal((await db.ref(originalPath).get()).exists(), false);
      const diagnostics = [];
      assert.deepEqual(await reconcileStoredCancellations(db, {
        reportDiagnostic: (code) => diagnostics.push(code),
      }), { scanned: 1, projected: 1 });
      assert.deepEqual(diagnostics, []);
      const recovered = (await db.ref(originalPath).get()).val();
      assert.equal(recovered.cancelledBySeq, 2);
      assert.equal(recovered.cancelledAt, cancelRow.receivedAt);
      assert.deepEqual(await reconcileStoredCancellations(db), { scanned: 1, projected: 0 });
      const duplicate = await ingestMqttEvent(topic, cancel, { ...options, db });
      assert.equal(duplicate.written, false);
      assert.deepEqual((await db.ref(`events/${id}_2`).get()).val(), cancelRow);
      assert.deepEqual((await db.ref(originalPath).get()).val(), recovered);
    }
    await root.remove();
  } finally {
    await deleteApp(app);
  }
});
