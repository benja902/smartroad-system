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
        historical: { userId: 'owner', criticalLegacyUserId: 'owner', type: 'sos', seq: 1 },
        current: { userId: 'owner', vehicleId: 'owned', criticalVehicleId: 'owned', type: 'crash', severity: 'grave', seq: 2 },
        vehicleOnly: { vehicleId: 'owned', criticalVehicleId: 'owned', type: 'sos', seq: 3 },
        technical: { userId: 'owner', vehicleId: 'owned', type: 'status', seq: 4 },
        unrelated: { userId: 'other-owner', vehicleId: 'other', type: 'sos', seq: 5 },
        mistagged: { userId: 'pending', vehicleId: 'owned', type: 'sos', seq: 6 },
        unassociated: { id: 'SDA-UNKNOWN', type: 'crash', severity: 'grave', seq: 7, receivedAt: 1000 },
      },
      eventReadIndex: {
        vehicles: { owned: {
          '0000000000001000_a': { eventKey: 'current' },
          '0000000000003000_c': { eventKey: 'vehicleOnly' },
        }, other: { '0000000000002000_b': { eventKey: 'unrelated' } } },
        users: { owner: { '0000000000000000_h': { eventKey: 'historical' } } },
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

test('bounded owner queries retain authorization and use event-key order', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await context.database().ref('events').update({
      'SDA-OWNED_9': { userId: 'owner', vehicleId: 'owned', type: 'sos', seq: 9, receivedAt: 1000 },
      'SDA-OWNED_10': { userId: 'owner', vehicleId: 'owned', type: 'sos', seq: 10, receivedAt: 2000 },
      'SDA-OWNED_11': { userId: 'owner', vehicleId: 'owned', type: 'sos', seq: 11, receivedAt: 3000 },
    });
  });
  for (const [field, value] of [['userId', 'owner'], ['vehicleId', 'owned']]) {
    const snapshot = await assertSucceeds(db('owner').ref('events')
      .orderByChild(field).equalTo(value).limitToLast(2).once('value'));
    assert.equal(snapshot.numChildren(), 2);
    assert.equal(snapshot.hasChild('SDA-OWNED_11'), false);
  }
  await assertFails(db('other-owner').ref('events')
    .orderByChild('vehicleId').equalTo('owned').limitToLast(2).once('value'));
});

test('chronological owner index selects newest times and denies other readers', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await context.database().ref('eventReadIndex/vehicles/owned').update({
      '0000000000002000_b': { eventKey: 'SDA-OWNED_9' },
      '0000000000004000_d': { eventKey: 'SDA-OWNED_11' },
    });
  });
  const recent = await assertSucceeds(db('owner').ref('eventReadIndex/vehicles/owned')
    .orderByKey().limitToLast(2).once('value'));
  assert.deepEqual(Object.values(recent.val()).map((pointer) => pointer.eventKey),
    ['vehicleOnly', 'SDA-OWNED_11']);
  const legacy = await assertSucceeds(db('owner').ref('eventReadIndex/users/owner')
    .orderByKey().limitToLast(100).once('value'));
  assert.equal(legacy.val()['0000000000000000_h'].eventKey, 'historical');
  for (const uid of ['active', 'other-owner', 'stranger', null]) {
    await assertFails(db(uid).ref('eventReadIndex/vehicles/owned')
      .orderByKey().limitToLast(100).once('value'));
    await assertFails(db(uid).ref('eventReadIndex/users/owner')
      .orderByKey().limitToLast(100).once('value'));
  }
  await assertFails(db('owner').ref('eventReadIndex').once('value'));
  await assertFails(db('owner').ref('eventReadIndex/vehicles/owned/test')
    .set({ eventKey: 'unrelated' }));
});

test('bounded critical indexes retain older owner events without granting contact access', async () => {
  const legacy = await assertSucceeds(db('owner').ref('events')
    .orderByChild('criticalLegacyUserId').equalTo('owner').limitToLast(100).once('value'));
  assert.deepEqual(Object.keys(legacy.val()), ['historical']);
  const current = await assertSucceeds(db('owner').ref('events')
    .orderByChild('criticalVehicleId').equalTo('owned').limitToLast(100).once('value'));
  assert.deepEqual(Object.keys(current.val()).sort(), ['current', 'vehicleOnly']);
  for (const uid of ['active', 'pending', 'stranger', null]) {
    await assertFails(db(uid).ref('events')
      .orderByChild('criticalVehicleId').equalTo('owned').limitToLast(100).once('value'));
  }
  await assertFails(db('other-owner').ref('events')
    .orderByChild('criticalLegacyUserId').equalTo('owner').limitToLast(100).once('value'));
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

test('A06: incident without association is invisible in app queries and direct reads', async () => {
  await env.withSecurityRulesDisabled(async context => {
    assert.equal((await context.database().ref('events/unassociated').once('value')).exists(), true);
  });

  for (const [uid, vehicleId] of [['owner', 'owned'], ['other-owner', 'other']]) {
    const historical = await assertSucceeds(db(uid).ref('events')
      .orderByChild('userId').equalTo(uid).once('value'));
    const current = await assertSucceeds(db(uid).ref('events')
      .orderByChild('vehicleId').equalTo(vehicleId).once('value'));
    assert.equal(historical.hasChild('unassociated'), false);
    assert.equal(current.hasChild('unassociated'), false);
    await assertFails(db(uid).ref('events/unassociated').once('value'));
  }
  for (const uid of ['stranger', null]) {
    await assertFails(db(uid).ref('events/unassociated').once('value'));
    await assertFails(db(uid).ref('events').orderByChild('userId').equalTo('owner').once('value'));
    await assertFails(db(uid).ref('events').orderByChild('vehicleId').equalTo('owned').once('value'));
  }
  await assertFails(db('owner').ref('userIncidentState/owner/unassociated')
    .set({ acknowledged: true }));
});

test('only the owner can read the active linked SDA, never the registry or an old device', async () => {
  await assertSucceeds(db('owner').ref('devices/SDA-OWNED').once('value'));
  await assertFails(db('owner').ref('devices').once('value'));
  await assertFails(db('owner').ref('devices/SDA-OTHER').once('value'));
  await assertFails(db('owner').ref('devices/SDA-LEGACY').once('value'));
  await assertFails(db('owner').ref('deviceRegistry/SDA-OWNED').once('value'));
  await assertFails(db('active').ref('devices/SDA-OWNED').once('value'));
});

test('owner SDA read follows the active reciprocal vehicle association', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await context.database().ref().update({
      'vehicles/owned/deviceId': 'SDA-REPLACEMENT',
      'deviceRegistry/SDA-REPLACEMENT': { vehicleId: 'owned', active: true },
      'devices/SDA-REPLACEMENT': { online: true },
    });
  });
  await assertFails(db('owner').ref('devices/SDA-OWNED').once('value'));
  await assertSucceeds(db('owner').ref('devices/SDA-REPLACEMENT').once('value'));
  await assertFails(db('active').ref('devices/SDA-REPLACEMENT').once('value'));
  await env.withSecurityRulesDisabled(async context => {
    await context.database().ref('deviceRegistry/SDA-REPLACEMENT/active').set(false);
  });
  await assertFails(db('owner').ref('devices/SDA-REPLACEMENT').once('value'));
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

test('pending invitation reference resolves only the own proposal without vehicleIds', async () => {
  const profile = await assertSucceeds(db('pending').ref('users/pending').once('value'));
  assert.equal(profile.hasChild('vehicleIds'), false);
  const proposal = await assertSucceeds(db('pending').ref('vehicleContacts/owned/pending').once('value'));
  assert.deepEqual(proposal.val(), { status: 'pending' });
  await assertFails(db('stranger').ref('vehicleContacts/owned/pending').once('value'));
  await assertFails(db(null).ref('vehicleContacts/owned/pending').once('value'));
  await assertFails(db('pending').ref('vehicleContacts/owned/active').once('value'));
  await assertFails(db('pending').ref('vehicleContacts/other/pending').once('value'));
  await assertFails(db('pending').ref('vehicleContacts/owned').once('value'));
  for (const path of ['users/owner', 'vehicles/owned', 'devices/SDA-OWNED',
    'deviceRegistry/SDA-OWNED', 'events/current', 'contactIncidents/owned']) {
    await assertFails(db('pending').ref(path).once('value'));
  }
});

test('pending invitation reference cannot activate a relation or write a discovery index', async () => {
  await assertFails(db('pending').ref('vehicleContacts/owned/pending')
    .set({ status: 'active', activeFrom: 1000 }));
  await assertFails(db('pending').ref('users/pending/vehicleIds/owned').set(true));
  await assertFails(db('pending').ref('vehicleContacts/owned/pending').remove());
  const proposal = await assertSucceeds(db('pending').ref('vehicleContacts/owned/pending').once('value'));
  assert.deepEqual(proposal.val(), { status: 'pending' });
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

test('contact discovery reads the own map and verifies only the own relationship', async () => {
  const index = await assertSucceeds(db('active').ref('users/active/vehicleIds').once('value'));
  assert.deepEqual(index.val(), { owned: true });
  const relation = await assertSucceeds(db('active').ref('vehicleContacts/owned/active').once('value'));
  assert.equal(relation.val().status, 'active');
  await assertFails(db('active').ref('users/owner/vehicleIds').once('value'));
  await assertFails(db('active').ref('vehicleContacts').once('value'));
  await assertFails(db('active').ref('vehicleContacts/owned/pending').once('value'));
  await assertFails(db(null).ref('users/active/vehicleIds').once('value'));
});

test('stale discovery indexes cannot override pending or revoked relationships', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await context.database().ref().update({
      'users/pending/vehicleIds': { owned: true },
      'users/revoked/vehicleIds': { owned: true },
    });
  });
  for (const uid of ['pending', 'revoked']) {
    await assertSucceeds(db(uid).ref(`users/${uid}/vehicleIds`).once('value'));
    await assertSucceeds(db(uid).ref(`vehicleContacts/owned/${uid}`).once('value'));
    await assertFails(db(uid).ref('contactIncidents/owned').once('value'));
    await assertFails(db(uid).ref('vehicles/owned').once('value'));
    await assertFails(db(uid).ref('devices/SDA-OWNED').once('value'));
    await assertFails(db(uid).ref('events/current').once('value'));
  }
  await assertSucceeds(db('active').ref('contactIncidents/owned').once('value'));
  await env.withSecurityRulesDisabled(async context => {
    await context.database().ref('vehicleContacts/owned/active').update({
      status: 'revoked', revokedAt: 2000,
    });
  });
  // Leave vehicleIds in place to demonstrate that the index is not authority.
  await assertFails(db('active').ref('contactIncidents/owned').once('value'));
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
