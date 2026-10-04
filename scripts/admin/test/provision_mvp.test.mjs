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
  const auth = { 'owner-test': { exists: true, disabled: false }, 'contact-test': { exists: true, disabled: false } };
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
