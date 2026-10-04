import assert from 'node:assert/strict';
import test from 'node:test';
import { ProvisionError } from '../provision_mvp_core.mjs';
import { runContactProfileProvision } from '../provision_contact_profiles_core.mjs';

function fixture() {
  const data = {
    users: { 'owner-test': { name: 'Owner', vehicleIds: { 'vehicle-test': true } } },
    vehicles: { 'vehicle-test': { ownerId: 'owner-test', deviceId: 'SDA-TEST-T001' } },
    devices: { 'SDA-TEST-T001': { state: 'idle' }, 'legacy-test': { state: 'idle' } },
    deviceRegistry: { 'SDA-TEST-T001': { vehicleId: 'vehicle-test', active: true } },
    vehicleContacts: {}, events: { incident: { cancelledBySeq: 2 } },
    userIncidentState: { 'owner-test': { incident: { acknowledged: true } } },
  };
  const auth = {
    'owner-test': { exists: true, disabled: false, email: 'owner@example.test' },
    'contact-test': { exists: true, disabled: true, email: 'contact@example.test' },
  };
  const writes = [];
  const adapter = {
    async readSnapshot() { return structuredClone(data); },
    async verifyUsers(ids) { return Object.fromEntries(ids.map(uid => [uid, auth[uid] ?? { exists: false }])); },
    async updateFields(patch) {
      writes.push(structuredClone(patch));
      for (const [path, value] of Object.entries(patch)) {
        const parts = path.split('/');
        let node = data;
        for (const part of parts.slice(0, -1)) node = node[part] ??= {};
        node[parts.at(-1)] = value;
      }
    },
  };
  return { data, auth, writes, adapter };
}

const contact = { uid: 'contact-test', name: 'Contacto real', confirmed: true };
const options = { contacts: [contact], confirmedSuffix: 'T001' };

test('default dry-run proposes only a real disabled contact profile, without writes or private values', async () => {
  const f = fixture(), before = structuredClone(f.data);
  const report = await runContactProfileProvision(f.adapter, options);
  assert.equal(report.mode, 'dry-run');
  assert.equal(report.writesPerformed, 0);
  assert.deepEqual(report.proposedChanges.map(change => change.path), [
    'users/{confirmedContact1}/name', 'users/{confirmedContact1}/email',
  ]);
  assert.deepEqual(f.writes, []);
  assert.deepEqual(f.data, before);
  const displayed = JSON.stringify(report);
  for (const privateValue of [contact.uid, contact.name, f.auth[contact.uid].email]) {
    assert.ok(!displayed.includes(privateValue));
  }
});

test('profile update is field-only and idempotent in memory', async () => {
  const f = fixture(), before = structuredClone(f.data);
  f.data.users[contact.uid] = { phone: '+00000000000' };
  const first = await runContactProfileProvision(f.adapter, { ...options, apply: true });
  assert.equal(first.writesPerformed, 1);
  assert.deepEqual(Object.keys(f.writes[0]).sort(), [
    `users/${contact.uid}/name`, `users/${contact.uid}/email`,
  ].sort());
  assert.equal(f.data.users[contact.uid].phone, '+00000000000');
  for (const node of ['vehicles', 'devices', 'deviceRegistry', 'vehicleContacts', 'events', 'userIncidentState']) {
    assert.deepEqual(f.data[node], before[node]);
  }
  const second = await runContactProfileProvision(f.adapter, { ...options, apply: true });
  assert.equal(second.writesPerformed, 0);
  assert.deepEqual(second.proposedChanges, []);
  assert.equal(f.writes.length, 1);
});

test('three contact slots are supported and incompatible or enabled accounts are rejected', async () => {
  const scenarios = [
    ['CONTACT_ACCOUNT_MUST_BE_DISABLED', f => { f.auth[contact.uid].disabled = false; }],
    ['CONTACT_AUTH_NOT_CONFIRMED', f => { delete f.auth[contact.uid]; }],
    ['CONTACT_PROFILE_CONFLICT', f => { f.data.users[contact.uid] = { email: 'other@example.test' }; }],
    ['CONFIRMED_CONTACT_REQUIRED', f => { f.input = { ...contact, password: true }; }],
    ['CONTACT_LIMIT_EXCEEDED', f => {
      f.data.vehicleContacts['vehicle-test'] = Object.fromEntries(
        ['contact-a', 'contact-b', 'contact-c'].map(uid => [uid, { status: 'pending' }]));
    }],
  ];
  for (const [expected, change] of scenarios) {
    const f = fixture(); change(f);
    const before = structuredClone(f.data);
    await assert.rejects(runContactProfileProvision(f.adapter, {
      ...options, contacts: [f.input ?? contact], apply: true,
    }),
      error => error instanceof ProvisionError && error.code === expected);
    assert.deepEqual(f.writes, []);
    assert.deepEqual(f.data, before);
  }
  const f = fixture();
  for (const uid of ['contact-a', 'contact-b']) {
    f.auth[uid] = { exists: true, disabled: true, email: `${uid}@example.test` };
  }
  const report = await runContactProfileProvision(f.adapter, {
    contacts: [contact, ...['contact-a', 'contact-b'].map(uid => ({ uid, name: uid, confirmed: true }))],
    confirmedSuffix: 'T001',
  });
  assert.equal(report.proposedChanges.length, 6);
  assert.equal(f.writes.length, 0);
});
