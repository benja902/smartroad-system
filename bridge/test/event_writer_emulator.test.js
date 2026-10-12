import assert from 'node:assert/strict';
import test from 'node:test';
import { persistEvent } from '../event_writer.js';
import { AssociationLookupError, resolveAssociation } from '../association_resolver.js';

const emulatorOnly = process.env.FIREBASE_DATABASE_EMULATOR_HOST === '127.0.0.1:19000' &&
  process.env.GCLOUD_PROJECT === 'demo-smartroad-bridge';

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
