import assert from 'node:assert/strict';
import { before, beforeEach, after, test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getDatabase } from 'firebase-admin/database';
import { getAuth } from 'firebase-admin/auth';
import { readBackendConfig, startBackend } from '../backend.js';
const project = 'demo-smartroad-startup';
assert.equal(process.env.GCLOUD_PROJECT, project);
assert.equal(process.env.FIREBASE_DATABASE_EMULATOR_HOST, '127.0.0.1:19000');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:19099');
const app = initializeApp({ projectId: project,
  databaseURL: `https://${project}-default-rtdb.firebaseio.com`,
  credential: { getAccessToken: async () => ({ access_token: 'owner', expires_in: 3600 }) },
});
const db = getDatabase(app), auth = getAuth(app);
const config = { ...readBackendConfig({ BACKEND_MODE: 'http-api',
  DATABASE_URL: `https://${project}-default-rtdb.firebaseio.com`, FIREBASE_PROJECT_ID: project,
  FIREBASE_DATABASE_EMULATOR_HOST: '127.0.0.1:19000', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:19099' }), port: 0 };
before(async () => {
  await db.setRules(await readFile(new URL('../../database.rules.json', import.meta.url), 'utf8'));
});
beforeEach(async () => {
  await db.ref().set({ users: { owner: { ownerVehicleId: 'v', vehicleIds: { v: true } }, contact: { name: 'Fixture' } },
    vehicles: { v: { ownerId: 'owner', deviceId: 'SDA-TEST' } },
    vehicleContacts: { v: { contact: { status: 'active', activeFrom: 123 } } },
    events: { 'SDA-TEST_1': { id: 'SDA-TEST', seq: 1, type: 'sos', receivedAt: 123 } },
  });
});
after(() => deleteApp(app));
async function waitForIndex() {
  for (let i = 0; i < 100; i++) {
    if ((await db.ref('users/contact/vehicleIds/v').get()).val() === true) return;
    await new Promise(resolve => setTimeout(resolve, 10));
  }
  assert.fail('contact index not repaired');
}

test('API startup and restart recover the contact index without touching incidents or owner index', async () => {
  const relation = (await db.ref('vehicleContacts/v/contact').get()).val();
  const events = (await db.ref('events').get()).val();
  for (let restart = 0; restart < 2; restart++) {
    await db.ref('users/contact/vehicleIds/v').remove();
    const service = await startBackend({ config, db, auth,
      loadMqtt: () => { throw Error('MQTT must not load in API mode'); } });
    try {
      await waitForIndex();
      assert.deepEqual((await db.ref('events').get()).val(), events);
      assert.deepEqual((await db.ref('vehicleContacts/v/contact').get()).val(), relation);
      assert.equal((await db.ref('users/owner/vehicleIds/v').get()).val(), true);
    } finally { await service.stop(); }
  }
});

test('API runtime verifies a fictitious Firebase token and keeps contact incidents closed', async () => {
  await db.ref('vehicleContacts/v/contact').set({ status: 'pending' });
  try { await auth.deleteUser('contact'); } catch {}
  await auth.createUser({ uid: 'contact', email: 'contact@example.test', password: 'Fictitious-Password-123' });
  const login = await fetch('http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fixture', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'contact@example.test', password: 'Fictitious-Password-123', returnSecureToken: true }),
  });
  const { idToken } = await login.json(); assert.ok(idToken);
  const service = await startBackend({ config, db, auth,
    loadMqtt: () => { throw Error('MQTT forbidden'); } });
  try {
    const base = `http://127.0.0.1:${service.server.address().port}`;
    assert.equal((await fetch(base + '/healthz')).status, 200);
    const response = await fetch(base + '/contacts/accept', {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
      body: JSON.stringify({ vehicleId: 'v' }),
    });
    assert.equal(response.status, 200); assert.equal((await response.json()).status, 'active');
    await waitForIndex();
    const denied = await fetch(`http://127.0.0.1:19000/contactIncidents/v.json?ns=${project}-default-rtdb&auth=${encodeURIComponent(idToken)}`);
    assert.equal(denied.status, 401);
  } finally { await service.stop(); }
});
