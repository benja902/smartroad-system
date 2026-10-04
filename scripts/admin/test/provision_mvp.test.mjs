import assert from 'node:assert/strict';
import test from 'node:test';
import { ProvisionError, runProvision } from '../provision_mvp_core.mjs';

const request = {
  ownerUid: 'owner-test', vehicleId: 'vehicle-test', deviceId: 'SDA-TEST-T001', deviceConfirmed: true,
};

function fixture() {
  const data = {
    users: {
      'owner-test': { name: 'Owner test', vehicleIds: { 'vehicle-test': true } },
      'contact-test': { name: 'Contact test' },
    },
    vehicles: { 'vehicle-test': { ownerId: 'owner-test', deviceId: 'SDA-TEST-T001', brand: 'Test', model: 'Test', plate: 'TEST' } },
    devices: { 'SDA-TEST-T001': { state: 'idle', power: { battery_v: 4 } }, 'legacy-test': { status: { online: true } } },
    events: { 'historical-test': { acknowledged: true, cancelledBySeq: 2 } },
    userIncidentState: { 'owner-test': { 'historical-test': { acknowledged: true } } },
    deviceRegistry: {}, vehicleContacts: {},
  };
  const auth = { 'owner-test': { exists: true, disabled: false }, 'contact-test': { exists: true, disabled: true } };
  const writes = [];
  const adapter = {
    async readSnapshot() { return structuredClone(data); },
    async verifyUsers(ids) { return Object.fromEntries(ids.map(uid => [uid, auth[uid] ?? { exists: false }])); },
    async updateFields(patch) {
      writes.push(structuredClone(patch));
      for (const [path, value] of Object.entries(patch)) {
        const parts = path.split('/');
        let target = data;
        for (const part of parts.slice(0, -1)) target = target[part] ??= {};
        target[parts.at(-1)] = value;
      }
    },
  };
  return { data, auth, writes, adapter };
}

test('default dry-run proposes confirmed fields without writes or sensitive logs', { timeout: 5000 }, async () => {
  const { data, writes, adapter } = fixture(), before = structuredClone(data);
  const report = await runProvision(adapter, { request: {
    ...request, rockblockImei: '000000000000001', imeiConfirmed: true,
    contacts: [{ uid: 'contact-test', confirmed: true }],
  } });
  assert.equal(report.mode, 'dry-run');
  assert.equal(report.writesPerformed, 0);
  assert.equal(report.proposedChanges.length, 4);
  assert.equal(report.proposedChanges.at(-1).value, 'pending');
  assert.deepEqual(writes, []);
  assert.deepEqual(data, before);
  const output = JSON.stringify(report);
  for (const sensitive of [request.ownerUid, request.vehicleId, request.deviceId, 'contact-test', '000000000000001']) {
    assert.ok(!output.includes(sensitive));
  }
  const selectedReport = await runProvision(adapter, { confirmedSuffix: 'T001' });
  assert.equal(selectedReport.proposedChanges.length, 2);
  assert.equal(selectedReport.optionalInputs.confirmedImeiSupplied, false);
  assert.equal(selectedReport.optionalInputs.confirmedContacts, 0);
  assert.deepEqual(writes, []);
});

test('repeated provision is idempotent and preserves all existing data', { timeout: 5000 }, async () => {
  const { data, writes, adapter } = fixture(), before = structuredClone(data);
  data.deviceRegistry[request.deviceId] = { vehicleId: request.vehicleId, note: 'preserve' };
  data.vehicleContacts[request.vehicleId] = { 'contact-test': { status: 'revoked', revokedAt: 123 } };
  const input = { ...request, rockblockImei: '000000000000001', imeiConfirmed: true, contacts: [{ uid: 'contact-test', confirmed: true }] };
  const first = await runProvision(adapter, { request: input, apply: true });
  assert.equal(first.writesPerformed, 1);
  assert.deepEqual(Object.keys(writes[0]).sort(), [
    `deviceRegistry/${request.deviceId}/active`, `deviceRegistry/${request.deviceId}/rockblockImei`,
  ].sort());
  assert.deepEqual(data.vehicleContacts[request.vehicleId]['contact-test'], { status: 'revoked', revokedAt: 123 });
  assert.equal(data.deviceRegistry[request.deviceId].note, 'preserve');
  for (const node of ['users', 'vehicles', 'devices', 'events', 'userIncidentState']) assert.deepEqual(data[node], before[node]);
  const afterFirst = structuredClone(data);
  const second = await runProvision(adapter, { request: input, apply: true });
  assert.deepEqual(second.proposedChanges, []);
  assert.equal(second.writesPerformed, 0);
  assert.equal(writes.length, 1);
  assert.deepEqual(data, afterFirst);
});

test('incompatible associations and unconfirmed identities abort before writes', { timeout: 5000 }, async () => {
  const scenarios = [
    ['VEHICLE_ASSOCIATION_CONFLICT', f => { f.data.vehicles['vehicle-test'].ownerId = 'other-test'; }],
    ['VEHICLE_ASSOCIATION_CONFLICT', f => { f.data.vehicles['vehicle-test'].deviceId = 'legacy-test'; }],
    ['OWNER_AUTH_NOT_CONFIRMED', f => { f.auth['owner-test'].disabled = true; }],
    ['EXACTLY_ONE_VEHICLE_REQUIRED', f => { f.data.vehicles['other-test'] = { ...f.data.vehicles['vehicle-test'] }; }],
    ['REGISTRY_ASSOCIATION_CONFLICT', f => { f.data.deviceRegistry[request.deviceId] = { vehicleId: 'other-test', active: true }; }],
    ['OTHER_ACTIVE_DEVICE_CONFLICT', f => { f.data.deviceRegistry['legacy-test'] = { vehicleId: request.vehicleId, active: true }; }],
    ['OWNER_VEHICLE_INDEX_CONFLICT', f => { f.data.users['owner-test'].vehicleIds = {}; }],
    ['DEVICE_NOT_FOUND', f => { delete f.data.devices[request.deviceId]; }],
    ['IMEI_ASSOCIATION_CONFLICT', f => {
      f.input.rockblockImei = '000000000000001'; f.input.imeiConfirmed = true;
      f.data.deviceRegistry['legacy-test'] = { rockblockImei: f.input.rockblockImei };
    }],
    ['CONFIRMED_IMEI_REQUIRED', f => { f.input.rockblockImei = '000000000000001'; }],
    ['CONFIRMED_CONTACT_REQUIRED', f => { f.input.contacts = [{ uid: 'contact-test' }]; }],
    ['CONTACT_PROFILE_OR_AUTH_NOT_CONFIRMED', f => { f.input.contacts = [{ uid: 'missing-test', confirmed: true }]; }],
    ['CONTACT_ACCOUNT_MUST_BE_DISABLED', f => {
      f.auth['contact-test'].disabled = false;
      f.input.contacts = [{ uid: 'contact-test', confirmed: true }];
    }],
    ['CONTACT_LIMIT_EXCEEDED', f => {
      f.data.vehicleContacts[request.vehicleId] = Object.fromEntries(
        ['contact-a', 'contact-b', 'contact-c'].map(uid => [uid, { status: 'pending' }]));
      f.input.contacts = [{ uid: 'contact-test', confirmed: true }];
    }],
  ];
  for (const [expected, mutate] of scenarios) {
    const f = fixture(); f.input = structuredClone(request); mutate(f);
    const before = structuredClone(f.data);
    await assert.rejects(runProvision(f.adapter, { request: f.input, apply: true }),
      error => error instanceof ProvisionError && error.code === expected);
    assert.deepEqual(f.writes, [], expected);
    assert.deepEqual(f.data, before, expected);
  }
});

test('three pending contacts fit, a fourth is rejected, and revoked contacts free a slot', { timeout: 5000 }, async () => {
  const f = fixture();
  for (const uid of ['contact-a', 'contact-b']) {
    f.data.users[uid] = { name: uid };
    f.auth[uid] = { exists: true, disabled: true };
  }
  const contacts = ['contact-test', 'contact-a', 'contact-b']
    .map(uid => ({ uid, confirmed: true }));
  const report = await runProvision(f.adapter, { request: { ...request, contacts } });
  assert.equal(report.proposedChanges.filter(change => change.value === 'pending').length, 3);
  assert.equal(f.writes.length, 0);

  f.data.vehicleContacts[request.vehicleId] = {
    'contact-c': { status: 'revoked' },
  };
  const stillFits = await runProvision(f.adapter, { request: { ...request, contacts } });
  assert.equal(stillFits.proposedChanges.filter(change => change.value === 'pending').length, 3);

  f.data.users['contact-c'] = { name: 'Contact C' };
  f.auth['contact-c'] = { exists: true, disabled: true };
  await assert.rejects(runProvision(f.adapter, { request: { ...request, contacts: [
    ...contacts, { uid: 'contact-c', confirmed: true },
  ] } }), error => error instanceof ProvisionError && error.code === 'CONTACT_LIMIT_EXCEEDED');
  assert.equal(f.writes.length, 0);
});

test('private profile input proposes only a pending relation and is idempotent', { timeout: 5000 }, async () => {
  const f = fixture();
  f.data.deviceRegistry[request.deviceId] = { vehicleId: request.vehicleId, active: true,
    rockblockImei: '000000000000001' };
  f.data.users['contact-test'].email = 'contact@example.test';
  f.auth['contact-test'].email = 'contact@example.test';
  const contactProfiles = [{ uid: 'contact-test', name: 'Contact test', confirmed: true }];
  const before = structuredClone(f.data);
  const options = { confirmedSuffix: 'T001', contactProfiles };
  const dryRun = await runProvision(f.adapter, options);
  assert.deepEqual(dryRun.proposedChanges, [{
    path: 'vehicleContacts/{existingVehicle}/{confirmedContact1}/status',
    previous: 'absent', value: 'pending',
  }]);
  assert.equal(dryRun.writesPerformed, 0);
  assert.deepEqual(f.data, before);
  const applied = await runProvision(f.adapter, { ...options, apply: true });
  assert.equal(applied.writesPerformed, 1);
  assert.deepEqual(Object.keys(f.writes[0]), [
    `vehicleContacts/${request.vehicleId}/contact-test/status`,
  ]);
  assert.equal(f.data.vehicleContacts[request.vehicleId]['contact-test'].status, 'pending');
  const repeated = await runProvision(f.adapter, options);
  assert.deepEqual(repeated.proposedChanges, []);
  assert.equal(repeated.writesPerformed, 0);
  for (const node of ['users', 'vehicles', 'devices', 'deviceRegistry', 'events', 'userIncidentState']) {
    assert.deepEqual(f.data[node], before[node]);
  }
});

test('private profile input rejects a mismatched confirmed profile', { timeout: 5000 }, async () => {
  const f = fixture();
  f.data.users['contact-test'].email = 'contact@example.test';
  f.auth['contact-test'].email = 'contact@example.test';
  const options = { confirmedSuffix: 'T001', contactProfiles: [
    { uid: 'contact-test', name: 'Other name', confirmed: true },
  ], apply: true };
  await assert.rejects(runProvision(f.adapter, options), error => error instanceof ProvisionError
    && error.code === 'CONTACT_PROFILE_CONFLICT');
  assert.deepEqual(f.writes, []);
  options.contactProfiles[0].name = 'Contact test';
  f.auth['contact-test'].email = 'different@example.test';
  await assert.rejects(runProvision(f.adapter, options), error => error instanceof ProvisionError
    && error.code === 'CONTACT_PROFILE_CONFLICT');
  assert.deepEqual(f.writes, []);
});
