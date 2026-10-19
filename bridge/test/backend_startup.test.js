import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { createContactHandler } from '../contact_operations.js';
import { readBackendConfig, startBackend } from '../backend.js';

const databaseURL = 'https://demo-smartroad-startup-default-rtdb.firebaseio.com';
const apiEnv = { BACKEND_MODE: 'http-api', DATABASE_URL: databaseURL, FIREBASE_PROJECT_ID: 'demo-smartroad-startup' };
const mqttEnv = { DATABASE_URL: databaseURL, MQTT_HOST: 'broker.example.test', MQTT_PASS: 'fictitious-only' };
const emulatorEnv = { ...apiEnv, FIREBASE_DATABASE_EMULATOR_HOST: '127.0.0.1:19000', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:19099' };
const cloudEnv = { BACKEND_MODE: 'http-api', DATABASE_URL: 'https://fictional-project-default-rtdb.firebaseio.com',
  FIREBASE_PROJECT_ID: 'fictional-project', BACKEND_DEPLOYMENT: 'compose',
  GOOGLE_APPLICATION_CREDENTIALS: '/run/secrets/fixture', HTTP_TRUST_PROXY_IP: '172.30.42.2',
  CONTACT_PUBLIC_URL: 'https://api.example.test' };
function database() {
  const reads = [], updates = [];
  return { reads, updates, ref(path) { return {
    async get() { reads.push(path); return { val: () => null }; },
    async update(value) { updates.push({ path, value }); },
  }; } };
}
const tick = () => new Promise(resolve => setImmediate(resolve));
async function launch(t, env, overrides = {}) {
  const db = database();
  const runtime = await startBackend({ config: { ...readBackendConfig(env), port: 0 }, db,
    auth: { verifyIdToken: async () => { throw Error('fixture invalid token'); } }, ...overrides });
  t.after(() => runtime.stop());
  await tick();
  return { ...runtime, db, url: `http://127.0.0.1:${runtime.server.address().port}` };
}

test('http-api starts without MQTT credentials, loading MQTT, or incident recovery', async t => {
  let imports = 0;
  const app = await launch(t, apiEnv, { loadMqtt: async () => { imports++; throw Error('MQTT must not load'); } });
  assert.equal(imports, 0); assert.equal(app.client, undefined);
  assert.deepEqual(app.db.reads, [], 'disabled operations do not read real data');
  assert.equal(app.server.address().address, '0.0.0.0');
  for (const path of ['/', '/healthz', '/readyz']) assert.equal((await fetch(app.url + path)).status, 200);
  assert.equal((await fetch(app.url + '/contacts/accept', { method: 'POST' })).status, 503);
});

test('http-api emulator startup recovers only contact indexes, including after restart', async t => {
  for (let restart = 0; restart < 2; restart++) {
    const app = await launch(t, emulatorEnv, { loadMqtt: async () => { throw Error('MQTT forbidden'); } });
    assert.deepEqual(app.db.reads, ['vehicleContacts']);
    assert.equal(app.db.reads.some(path => path === 'events'), false);
    await app.stop();
  }
});

test('local mqtt-bridge preserves TLS session, topics, availability writes and health', async t => {
  const client = new EventEmitter(); client.connected = false; client.endAsync = async () => { client.ended = true; };
  let endpoint, options, subscription;
  client.subscribe = (topics, opts) => { subscription = { topics, opts }; };
  const app = await launch(t, mqttEnv, { connectMqtt: (url, opts) => { endpoint = url; options = opts; return client; } });
  assert.equal(endpoint, 'mqtts://broker.example.test:8883');
  assert.equal(options.clean, false); assert.equal(options.rejectUnauthorized, true);
  assert.equal(options.clientId, 'puente-urbes-sda-1'); assert.equal(options.username, 'lilygo');
  assert.equal(options.password, 'fictitious-only'); assert.equal(options.reconnectPeriod, 5000);
  assert.deepEqual(app.db.reads, ['events', 'events', 'events']);
  assert.equal((await fetch(app.url + '/')).status, 503);
  client.connected = true; client.emit('connect');
  assert.deepEqual(subscription, { topics: ['sda/+/event', 'sda/+/status', 'sda/+/position', 'sda/+/availability'], opts: { qos: 1 } });
  assert.equal((await fetch(app.url + '/readyz')).status, 200);
  client.emit('message', 'sda/SDA-TEST/availability', Buffer.from('online')); await tick();
  assert.deepEqual(app.db.updates, [{ path: 'devices/SDA-TEST', value: { online: true, lastSeen: { '.sv': 'timestamp' } } }]);
  assert.equal((await fetch(app.url + '/contacts/accept', { method: 'POST' })).status, 503);
  await app.stop(); assert.equal(client.ended, true);
});

test('API ignores unused MQTT configuration and defaults contact mutations to off', () => {
  const config = readBackendConfig({ ...apiEnv, MQTT_HOST: 'invalid/unused', MQTT_PASS: 'unused-fixture' });
  assert.equal(config.mqtt, undefined); assert.equal(config.realOperations, false); assert.equal(config.localEmulator, false);
  assert.equal(config.port, 8080);
});

for (const [label, env, code] of [
  ['unknown deployment', { ...apiEnv, BACKEND_DEPLOYMENT: 'other' }, 'INVALID_BACKEND_DEPLOYMENT'],
  ['missing external credentials', { ...cloudEnv, GOOGLE_APPLICATION_CREDENTIALS: undefined }, 'EXTERNAL_CREDENTIALS_REQUIRED'],
  ['missing proxy', { ...cloudEnv, HTTP_TRUST_PROXY_IP: undefined }, 'INVALID_TRUSTED_PROXY_IP'],
  ['public proxy IP', { ...cloudEnv, HTTP_TRUST_PROXY_IP: '198.51.100.1' }, 'INVALID_TRUSTED_PROXY_IP'],
  ['unknown mode', { ...mqttEnv, BACKEND_MODE: 'other' }, 'INVALID_BACKEND_MODE'],
  ['Compose missing mode', { ...mqttEnv, BACKEND_DEPLOYMENT: 'compose' }, 'BACKEND_MODE_REQUIRED_IN_COMPOSE'],
  ['missing URL', { ...apiEnv, DATABASE_URL: undefined }, 'INVALID_DATABASE_URL'],
  ['insecure URL', { ...apiEnv, DATABASE_URL: 'http://example.test' }, 'INVALID_DATABASE_URL'],
  ['URL credentials', { ...apiEnv, DATABASE_URL: 'https://user:fake@demo.firebaseio.com' }, 'INVALID_DATABASE_URL'],
  ['missing API project', { ...apiEnv, FIREBASE_PROJECT_ID: undefined }, 'PROJECT_ID_REQUIRED'],
  ['contradictory projects', { ...apiEnv, GCLOUD_PROJECT: 'demo-other-project' }, 'INVALID_PROJECT_ID'],
  ['invalid port', { ...apiEnv, PORT: '8080oops' }, 'INVALID_PORT'],
  ['out of range port', { ...apiEnv, PORT: '65536' }, 'INVALID_PORT'],
  ['missing MQTT password', { ...mqttEnv, MQTT_PASS: undefined }, 'INVALID_MQTT_CONFIGURATION'],
  ['MQTT prefix wildcard', { ...mqttEnv, MQTT_PREFIX: '#' }, 'INVALID_MQTT_PREFIX'],
  ['MQTT multi-level prefix', { ...mqttEnv, MQTT_PREFIX: 'sda/other' }, 'INVALID_MQTT_PREFIX'],
  ['invalid flag', { ...apiEnv, CONTACT_OPERATIONS_ENABLED: 'yes' }, 'INVALID_CONTACT_OPERATIONS_FLAG'],
  ['local real operations forbidden', { ...apiEnv, CONTACT_OPERATIONS_ENABLED: 'true' }, 'REAL_OPERATIONS_REQUIRE_COMPOSE'],
  ['insecure public URL', { ...cloudEnv, CONTACT_OPERATIONS_ENABLED: 'true', CONTACT_PUBLIC_URL: 'http://api.example.test' }, 'INVALID_PUBLIC_HTTPS_URL'],
  ['emulator in Compose forbidden', { ...emulatorEnv, BACKEND_DEPLOYMENT: 'compose' }, 'INVALID_EMULATOR_CONFIGURATION'],
  ['remote emulator forbidden', { ...emulatorEnv, FIREBASE_DATABASE_EMULATOR_HOST: 'example.test:19000' }, 'INVALID_EMULATOR_CONFIGURATION'],
  ['partial emulators forbidden for API', { ...emulatorEnv, FIREBASE_AUTH_EMULATOR_HOST: undefined }, 'BOTH_EMULATORS_REQUIRED'],
]) test(`configuration rejects ${label} before startup`, () => {
  assert.throws(() => readBackendConfig(env), { code });
});

test('Compose rejects direct requests even with spoofed HTTPS, host and a token', async t => {
  const verified = [];
  const app = await launch(t, { ...cloudEnv, CONTACT_OPERATIONS_ENABLED: 'true' }, {
    auth: { async verifyIdToken(token, checkRevoked) {
      verified.push({ token, checkRevoked });
      if (token !== 'fixture-token') throw Error('invalid token'); return { uid: 'fixture-contact' };
    } },
  });
  const request = headers => new Promise((resolve, reject) => {
    const req = http.request(app.url + '/contacts/accept', { method: 'POST', headers: {
      'Content-Type': 'application/json', ...headers,
    } }, response => { response.resume(); resolve({ status: response.statusCode }); });
    req.on('error', reject); req.end(JSON.stringify({ vehicleId: 'fixture-vehicle' }));
  });
  assert.equal((await request({ Authorization: 'Bearer fixture-token' })).status, 503);
  assert.equal(verified.length, 0);
  const secure = { Host: 'api.example.test', 'X-Forwarded-Proto': 'https' };
  assert.equal((await request(secure)).status, 503);
  assert.equal((await request({ ...secure, Authorization: 'Bearer invalid-fixture' })).status, 503);
  const authorized = await request({ ...secure, Authorization: 'Bearer fixture-token' });
  assert.equal(authorized.status, 503, 'untrusted TCP peer cannot reach authentication');
  assert.equal(verified.length, 0);
  assert.equal(verified.every(call => call.checkRevoked === true), true);
  assert.equal(app.db.updates.length, 0);
});

test('forwarded HTTPS header cannot enable operations without configured Compose mode', async t => {
  const app = await launch(t, apiEnv);
  const r = await fetch(app.url + '/contacts/accept', { method: 'POST', headers: {
    Host: 'api.example.test', 'X-Forwarded-Proto': 'https', Authorization: 'Bearer fixture-token',
  } });
  assert.equal(r.status, 503);
});

test('entrypoint rejects invalid configuration before ADC or any network connection', () => {
  const child = spawnSync(process.execPath, ['--input-type=module', '-e',
    `process.env.BACKEND_DEPLOYMENT='compose'; process.env.BACKEND_MODE='invalid'; await import(${JSON.stringify(new URL('../index.js', import.meta.url).href)});`],
    { encoding: 'utf8', timeout: 10000, env: { ...process.env, GOOGLE_APPLICATION_CREDENTIALS: 'not-a-real-file' } });
  assert.equal(child.status, 1); assert.match(child.stderr, /INVALID_BACKEND_MODE/);
});

test('Docker copies only runtime modules and installs the exact lockfile without bundled secrets', async () => {
  const root = new URL('../', import.meta.url);
  const docker = await readFile(new URL('Dockerfile', root), 'utf8');
  const ignore = await readFile(new URL('.dockerignore', root), 'utf8');
  const manifest = JSON.parse(await readFile(new URL('package.json', root), 'utf8'));
  const lock = JSON.parse(await readFile(new URL('package-lock.json', root), 'utf8'));
  assert.match(docker, /COPY package\.json package-lock\.json/);
  assert.match(docker, /npm ci --omit=dev --ignore-scripts/);
  assert.match(docker, /USER node/); assert.doesNotMatch(docker, /COPY \.|COPY \*/);
  assert.equal(ignore.split(/\r?\n/)[0], '**'); assert.doesNotMatch(ignore, /!.*(?:env|credential|key|test|node_modules)/i);
  assert.deepEqual(manifest.dependencies, lock.packages[''].dependencies);
  for (const entry of ignore.split(/\r?\n/).filter(line => line.startsWith('!'))) {
    await readFile(new URL(entry.slice(1), root));
  }
});


test('only the configured TCP proxy with matching HTTPS host reaches Firebase authentication', async () => {
  let verified = 0;
  const handler = createContactHandler({ realOperations: true, trustedProxyIp: '172.30.42.2',
    publicHost: 'api.example.test', db: database(), auth: { async verifyIdToken(token, revoked) {
      verified++; assert.equal(revoked, true);
      if (token === 'fixture-valid') return { uid: 'fixture-contact' };
      throw Error('fixture invalid token');
    } }, health: () => true });
  async function request(peer, host = 'api.example.test', proto = 'https', token = 'fixture') {
    let status;
    const response = { writeHead(code) { status = code; return this; }, end() {} };
    await handler({ method: 'POST', url: '/contacts/accept', socket: { remoteAddress: peer },
      headers: { host, 'x-forwarded-proto': proto, 'content-type': 'application/json',
        ...(token ? { authorization: `Bearer ${token}` } : {}) },
      async *[Symbol.asyncIterator]() { yield Buffer.from(JSON.stringify({ vehicleId: 'fixture-vehicle' })); },
    }, response);
    return status;
  }
  assert.equal(await request('172.30.42.3'), 503);
  assert.equal(await request('172.30.42.2', 'wrong.example.test'), 503);
  assert.equal(await request('172.30.42.2', undefined, 'http'), 503);
  assert.equal(verified, 0);
  assert.equal(await request('172.30.42.2', undefined, undefined, false), 401);
  assert.equal(await request('::ffff:172.30.42.2'), 401);
  assert.equal(verified, 1);
  assert.equal(await request('172.30.42.2', undefined, undefined, 'fixture-valid'), 409);
  assert.equal(verified, 2, 'valid Firebase identity still needs an existing relationship');
});

test('legacy Cloud Run variables cannot enable real operations', () => {
  assert.throws(() => readBackendConfig({ ...apiEnv, CONTACT_OPERATIONS_ENABLED: 'true',
    K_SERVICE: 'fixture', K_REVISION: 'fixture', K_CONFIGURATION: 'fixture' }), { code: 'REAL_OPERATIONS_REQUIRE_COMPOSE' });
});
