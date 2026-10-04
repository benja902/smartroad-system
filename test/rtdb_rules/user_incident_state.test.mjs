import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const projectId = 'demo-smartroad-rules';
// Refuse to run outside the CLI-managed local Database Emulator.
assert.match(process.env.FIREBASE_DATABASE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):19000$/);
const rules = await readFile(new URL('../../database.rules.json', import.meta.url), 'utf8');
let env;
const statePath = (event = 'historical', uid = 'owner') => `userIncidentState/${uid}/${event}`;
const db = (uid = 'owner') => uid === null
  ? env.unauthenticatedContext().database()
  : env.authenticatedContext(uid).database();

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    database: { host: '127.0.0.1', port: 19000, rules },
  });
});

beforeEach(async () => {
  await env.clearDatabase();
  await env.withSecurityRulesDisabled(async (context) => {
    await context.database().ref().set({
      users: {
        owner: { ownerVehicleId: 'owned', vehicleIds: { owned: true } },
        'other-owner': { ownerVehicleId: 'other', vehicleIds: { other: true } },
        'legacy-user': { name: 'Legacy' },
      },
      vehicles: {
        owned: { ownerId: 'owner', deviceId: 'SDA-TEST' },
        other: { ownerId: 'other-owner' },
      },
      events: {
        historical: { userId: 'owner', seq: 1 },
        vehicleOnly: { vehicleId: 'owned', seq: 2 },
        transitioned: { userId: 'legacy-user', vehicleId: 'owned', seq: 3 },
        unrelated: { userId: 'other-owner', vehicleId: 'other', seq: 4 },
        unassociated: { vehicleId: 'missing', seq: 5 },
        malformedVehicle: { vehicleId: 42, seq: 6 },
        cancelled: { vehicleId: 'owned', cancelledBySeq: 8, cancelledAt: 2000, seq: 7 },
      },
      userIncidentState: {
        owner: { historical: { acknowledged: true } },
        stranger: { unrelated: { acknowledged: true } },
      },
    });
  });
});

after(async () => { await env?.cleanup(); });

test('owner can read only their own state subtree', async () => {
  await assertSucceeds(db().ref('userIncidentState/owner').once('value'));
  await assertFails(db().ref('userIncidentState/stranger').once('value'));
  await assertFails(db().ref('userIncidentState').once('value'));
});

test('unauthenticated user cannot read or write state', async () => {
  await assertFails(db(null).ref(statePath()).once('value'));
  await assertFails(db(null).ref(statePath()).set({ acknowledged: true }));
});

test('historical userId allows boolean true and false', async () => {
  await assertSucceeds(db().ref(statePath()).set({ acknowledged: true }));
  await assertSucceeds(db().ref(statePath()).update({ acknowledged: false }));
});

test('vehicle owner can acknowledge event with no userId', async () => {
  await assertSucceeds(db().ref(statePath('vehicleOnly')).set({ acknowledged: true }));
});

test('vehicle owner can acknowledge despite different legacy userId', async () => {
  await assertSucceeds(db().ref(statePath('transitioned')).set({ acknowledged: false }));
});

test('userId alone cannot grant access to an event owned by another vehicle', async () => {
  await assertFails(db('legacy-user').ref(statePath('transitioned', 'legacy-user')).set({ acknowledged: true }));
});

test('user cannot write someone else state even for an owned event', async () => {
  await assertFails(db().ref(statePath('historical', 'stranger')).set({ acknowledged: true }));
});

test('stranger and contact-like user cannot acknowledge vehicle event', async () => {
  for (const uid of ['stranger', 'contact']) {
    await assertFails(db(uid).ref(statePath('vehicleOnly', uid)).set({ acknowledged: true }));
  }
});

test('own path does not authorize unrelated event', async () => {
  await assertFails(db().ref(statePath('unrelated')).set({ acknowledged: true }));
});

test('missing event, unknown vehicle and malformed vehicleId are denied', async () => {
  for (const key of ['missing', 'unassociated', 'malformedVehicle']) {
    await assertFails(db().ref(statePath(key)).set({ acknowledged: true }));
  }
});

test('acknowledged must be boolean', async () => {
  for (const value of ['true', 1, {}, [], null]) {
    await assertFails(db().ref(statePath('vehicleOnly')).set({ acknowledged: value }));
  }
});

test('missing acknowledgment and scalar state are denied', async () => {
  for (const value of [{ extra: true }, true, 'true']) {
    await assertFails(db().ref(statePath('vehicleOnly')).set(value));
  }
});

test('additional fields are denied for set and update', async () => {
  await assertFails(db().ref(statePath()).set({ acknowledged: true, note: 'extra' }));
  await assertFails(db().ref(statePath()).update({ note: 'extra' }));
});

test('deleting state or acknowledged is denied', async () => {
  await assertFails(db().ref(statePath()).remove());
  await assertFails(db().ref(`${statePath()}/acknowledged`).remove());
});

test('multipath update cannot include foreign state or extra fields', async () => {
  await assertFails(db().ref().update({
    [statePath()]: { acknowledged: false },
    [statePath('historical', 'stranger')]: { acknowledged: true },
  }));
  await assertFails(db().ref().update({
    [`${statePath()}/acknowledged`]: false,
    [`${statePath()}/extra`]: true,
  }));
  assert.equal((await db().ref(`${statePath()}/acknowledged`).once('value')).val(), true);
});

test('acknowledgment preserves canonical cancellation', async () => {
  const before = (await db().ref('events/cancelled').once('value')).val();
  await assertSucceeds(db().ref(statePath('cancelled')).set({ acknowledged: true }));
  assert.deepEqual((await db().ref('events/cancelled').once('value')).val(), before);
});

test('events indexes remain and global acknowledgment is backend-only', async () => {
  assert.deepEqual(JSON.parse(rules).rules.events['.indexOn'],
    ['userId', 'deviceId', 'seq', 'vehicleId']);
  await assertFails(db('stranger').ref('events').once('value'));
  await assertFails(db().ref('events').once('value'));
  await assertFails(db(null).ref('events').once('value'));
  await assertFails(db().ref('events/vehicleOnly').set({ seq: 999 }));
  await assertFails(db().ref('events/historical/acknowledged').set(true));
  await assertFails(db('stranger').ref('events/historical/acknowledged').set(true));
  await assertFails(db(null).ref('events/historical/acknowledged').set(true));
});

test('both indexed event queries remain available', async () => {
  const historical = await assertSucceeds(db().ref('events').orderByChild('userId').equalTo('owner').once('value'));
  const current = await assertSucceeds(db().ref('events').orderByChild('vehicleId').equalTo('owned').once('value'));
  assert.deepEqual(Object.keys(historical.val()), ['historical']);
  assert.deepEqual(Object.keys(current.val()).sort(), ['cancelled', 'transitioned', 'vehicleOnly']);
});
