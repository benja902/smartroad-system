import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';

const projectId = 'demo-smartroad-rules';
assert.match(process.env.FIREBASE_DATABASE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):19000$/);
const rules = await readFile(new URL('../../database.rules.json', import.meta.url), 'utf8');
let env;
const db = (uid) => uid === null
  ? env.unauthenticatedContext().database()
  : env.authenticatedContext(uid).database();

before(async () => {
  env = await initializeTestEnvironment({
    projectId, database: { host: '127.0.0.1', port: 19000, rules },
  });
});

beforeEach(async () => {
  await env.clearDatabase();
  await env.withSecurityRulesDisabled(async (context) => {
    await context.database().ref().set({
      users: {
        owner: { name: 'Owner', ownerVehicleId: 'owned', vehicleIds: { owned: true } },
        'other-owner': { name: 'Other owner', ownerVehicleId: 'other', vehicleIds: { other: true } },
        pending: { name: 'Pending' },
        active: { name: 'Active', vehicleIds: { owned: true } },
        revoked: { name: 'Revoked' },
        stranger: { name: 'Stranger' },
        forged: { name: 'Forged', ownerVehicleId: 'owned' },
      },
      vehicles: {
        owned: { ownerId: 'owner', deviceId: 'SDA-OWNED', brand: 'Test', model: 'Test', plate: 'TEST' },
        other: { ownerId: 'other-owner', deviceId: 'SDA-OTHER', brand: 'Other', model: 'Other', plate: 'OTHER' },
      },
      deviceRegistry: {
        'SDA-OWNED': { vehicleId: 'owned', active: true, rockblockImei: '000000000000001' },
        'SDA-OTHER': { vehicleId: 'other', active: true },
        'SDA-LEGACY': { vehicleId: 'owned', active: false },
      },
      devices: {
        'SDA-OWNED': { online: true, state: 'idle' },
        'SDA-OTHER': { online: true, state: 'idle' },
        'SDA-LEGACY': { online: false },
      },
      events: {
        historical: { userId: 'owner', type: 'sos', seq: 1 },
        current: { userId: 'owner', vehicleId: 'owned', type: 'crash', severity: 'grave', seq: 2 },
        vehicleOnly: { vehicleId: 'owned', type: 'sos', seq: 3 },
        technical: { userId: 'owner', vehicleId: 'owned', type: 'status', seq: 4 },
        unrelated: { userId: 'other-owner', vehicleId: 'other', type: 'sos', seq: 5 },
        mistagged: { userId: 'pending', vehicleId: 'owned', type: 'sos', seq: 6 },
      },
      vehicleContacts: {
        owned: {
          pending: { status: 'pending' },
          active: { status: 'active', activeFrom: 1000 },
          revoked: { status: 'revoked', revokedAt: 2000 },
        },
      },
      contactIncidents: {
        owned: { publicOne: { type: 'sos', severity: 'grave', vehicleLabel: 'Test' } },
      },
      satelliteDeliveries: { sample: { eventKey: 'current', receivedAt: 1000 } },
    });
  });
});

after(async () => { await env?.cleanup(); });

test('owner keeps the exact vehicle and dual event queries used by Flutter', async () => {
  const own = await assertSucceeds(db('owner').ref('vehicles')
    .orderByChild('ownerId').equalTo('owner').once('value'));
  assert.deepEqual(Object.keys(own.val()), ['owned']);
  const historical = await assertSucceeds(db('owner').ref('events')
    .orderByChild('userId').equalTo('owner').once('value'));
  assert.ok(historical.hasChild('historical'));
  const current = await assertSucceeds(db('owner').ref('events')
    .orderByChild('vehicleId').equalTo('owned').once('value'));
  assert.ok(current.hasChild('vehicleOnly'));
  await assertSucceeds(db('owner').ref('events/historical').once('value'));
  await assertSucceeds(db('owner').ref('events/vehicleOnly').once('value'));
});

test('owner cannot list all vehicles or events, query another owner, or read another event', async () => {
  await assertFails(db('owner').ref('vehicles').once('value'));
  await assertFails(db('owner').ref('events').once('value'));
  await assertFails(db('owner').ref('vehicles').orderByChild('ownerId').equalTo('other-owner').once('value'));
  await assertFails(db('owner').ref('events').orderByChild('userId').equalTo('other-owner').once('value'));
  await assertFails(db('owner').ref('events').orderByChild('vehicleId').equalTo('other').once('value'));
  await assertFails(db('owner').ref('events/unrelated').once('value'));
  await assertFails(db('owner').ref('vehicles/other').once('value'));
});

test('only the owner can read the active linked SDA, never the registry or an old device', async () => {
  await assertSucceeds(db('owner').ref('devices/SDA-OWNED').once('value'));
  await assertFails(db('owner').ref('devices').once('value'));
  await assertFails(db('owner').ref('devices/SDA-OTHER').once('value'));
  await assertFails(db('owner').ref('devices/SDA-LEGACY').once('value'));
  await assertFails(db('owner').ref('deviceRegistry/SDA-OWNED').once('value'));
  await assertFails(db('active').ref('devices/SDA-OWNED').once('value'));
});

test('owner can list contacts of their vehicle, not contacts of another vehicle', async () => {
  await assertSucceeds(db('owner').ref('vehicleContacts/owned').once('value'));
  await assertFails(db('owner').ref('vehicleContacts').once('value'));
  await assertFails(db('owner').ref('vehicleContacts/other').once('value'));
});

test('pending contact reads only their profile and own relation, not owner data', async () => {
  await assertSucceeds(db('pending').ref('users/pending').once('value'));
  await assertSucceeds(db('pending').ref('vehicleContacts/owned/pending').once('value'));
  await assertFails(db('pending').ref('users/owner').once('value'));
  await assertFails(db('pending').ref('vehicleContacts/owned').once('value'));
  await assertFails(db('pending').ref('vehicleContacts/owned/active').once('value'));
  await assertFails(db('pending').ref('vehicles/owned').once('value'));
  await assertFails(db('pending').ref('devices/SDA-OWNED').once('value'));
  await assertFails(db('pending').ref('contactIncidents/owned').once('value'));
});

test('pending or active contact cannot directly query canonical events, even when tagged', async () => {
  for (const uid of ['pending', 'active']) {
    await assertFails(db(uid).ref('events').once('value'));
    await assertFails(db(uid).ref('events').orderByChild('userId').equalTo(uid).once('value'));
    await assertFails(db(uid).ref('events').orderByChild('vehicleId').equalTo('owned').once('value'));
    await assertFails(db(uid).ref('events/current').once('value'));
    await assertFails(db(uid).ref('events/mistagged').once('value'));
    await assertFails(db(uid).ref('userIncidentState').child(uid).child('current')
      .set({ acknowledged: true }));
  }
});

test('active contact reads only the critical projection and their own relation', async () => {
  await assertSucceeds(db('active').ref('contactIncidents/owned').once('value'));
  await assertSucceeds(db('active').ref('vehicleContacts/owned/active').once('value'));
  await assertFails(db('active').ref('contactIncidents').once('value'));
  await assertFails(db('active').ref('devices/SDA-OWNED').once('value'));
  await assertFails(db('active').ref('vehicleContacts/owned/pending').once('value'));
});

test('revoked, unrelated and unauthenticated users cannot read projections', async () => {
  for (const uid of ['revoked', 'stranger', null]) {
    await assertFails(db(uid).ref('contactIncidents/owned').once('value'));
  }
  await assertFails(db(null).ref('users/owner').once('value'));
  await assertFails(db(null).ref('vehicleContacts/owned/pending').once('value'));
});

test('forged owner index is insufficient without matching vehicle ownership', async () => {
  await assertFails(db('forged').ref('vehicles').orderByChild('ownerId').equalTo('forged').once('value'));
  await assertFails(db('forged').ref('events').orderByChild('userId').equalTo('forged').once('value'));
  await assertFails(db('forged').ref('events').orderByChild('vehicleId').equalTo('owned').once('value'));
  await assertFails(db('forged').ref('devices/SDA-OWNED').once('value'));
});

test('owner queries stay closed until the administrative owner index exists', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await context.database().ref('users/owner/ownerVehicleId').remove();
  });
  await assertFails(db('owner').ref('vehicles').orderByChild('ownerId').equalTo('owner').once('value'));
  await assertFails(db('owner').ref('events').orderByChild('userId').equalTo('owner').once('value'));
  await assertFails(db('owner').ref('events').orderByChild('vehicleId').equalTo('owned').once('value'));
  await assertFails(db('owner').ref('devices/SDA-OWNED').once('value'));
  await assertFails(db('owner').ref('userIncidentState/owner/historical')
    .set({ acknowledged: true }));
});

test('clients cannot write administrative nodes, profile indexes, events or projections', async () => {
  const attempts = [
    ['users/owner/ownerVehicleId', 'other'],
    ['users/owner/vehicleIds/other', true],
    ['vehicles/owned/ownerId', 'active'],
    ['vehicles/owned/deviceId', 'SDA-OTHER'],
    ['devices/SDA-OWNED/online', false],
    ['deviceRegistry/SDA-OWNED/active', false],
    ['events/current/acknowledged', true],
    ['events/current/cancelledBySeq', null],
    ['vehicleContacts/owned/active/status', 'revoked'],
    ['contactIncidents/owned/publicOne/status', 'cancelled'],
    ['satelliteDeliveries/sample/eventKey', 'other'],
  ];
  for (const [path, value] of attempts) {
    await assertFails(db('owner').ref(path).set(value));
  }
  await assertFails(db('active').ref('vehicleContacts/owned/active/status').set('active'));
});

test('a multipath administrative write is rejected atomically', async () => {
  await assertFails(db('owner').ref().update({
    'userIncidentState/owner/historical/acknowledged': true,
    'vehicles/owned/ownerId': 'active',
  }));
  let ownerId;
  await env.withSecurityRulesDisabled(async context => {
    ownerId = (await context.database().ref('vehicles/owned/ownerId').once('value')).val();
  });
  assert.equal(ownerId, 'owner');
});
