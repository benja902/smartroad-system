import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
const image = 'urbes-backend:local';
function docker(args) {
  const result = spawnSync('docker', ['--context', 'desktop-linux', ...args], {
    encoding: 'utf8', timeout: 30000, windowsHide: true,
  });
  assert.ifError(result.error);
  return result;
}

test('local image starts API without network, secrets or MQTT; health and disabled mutations are correct', { timeout: 60000 }, async () => {
  const start = docker(['run', '--rm', '-d', '--network', 'none',
    '-e', 'BACKEND_MODE=http-api', '-e', 'PORT=8181',
    '-e', 'DATABASE_URL=https://demo-container-default-rtdb.firebaseio.com',
    '-e', 'FIREBASE_PROJECT_ID=demo-container', image]);
  assert.equal(start.status, 0, 'local container start');
  const id = start.stdout.trim(); assert.match(id, /^[a-f0-9]{64}$/);
  try {
    const probe = docker(['exec', id, 'node', '--input-type=module', '-e', `
      import assert from 'node:assert/strict';
      import { existsSync, readdirSync } from 'node:fs';
      assert.notEqual(process.getuid(), 0);
      assert.equal(process.env.GOOGLE_APPLICATION_CREDENTIALS, undefined);
      assert.equal(process.env.MQTT_PASS, undefined);
      assert.equal(existsSync('/app/.env'), false);
      const allowed = ['index.js', 'backend.js', 'mqtt_bridge.js', 'contact_operations.js',
        'event_writer.js', 'mqtt_event_normalizer.js', 'association_resolver.js',
        'package.json', 'package-lock.json', 'node_modules'].sort();
      assert.deepEqual(readdirSync('/app').sort(), allowed);
      let ready = false;
      for (let attempt = 0; attempt < 30; attempt++) {
        try { ready = (await fetch('http://127.0.0.1:8181/healthz')).status === 200; } catch {}
        if (ready) break; await new Promise(resolve => setTimeout(resolve, 100));
      }
      assert.equal(ready, true);
      assert.equal((await fetch('http://127.0.0.1:8181/readyz')).status, 200);
      const denied = await fetch('http://127.0.0.1:8181/contacts/accept', { method: 'POST' });
      assert.equal(denied.status, 503);
      console.log('isolated container smoke passed');
    `]);
    assert.equal(probe.status, 0, probe.stderr || probe.stdout);
  } finally { assert.equal(docker(['stop', '--time', '3', id]).status, 0); }
});

test('local image rejects invalid mode before Firebase initialization', () => {
  const result = docker(['run', '--rm', '--network', 'none', '-e', 'BACKEND_MODE=invalid', image]);
  assert.equal(result.status, 1); assert.match(result.stderr, /INVALID_BACKEND_MODE/);
});

test('local image rejects MQTT without credentials rather than starting another consumer', () => {
  const result = docker(['run', '--rm', '--network', 'none', '-e', 'BACKEND_MODE=mqtt-bridge',
    '-e', 'DATABASE_URL=https://demo-container-default-rtdb.firebaseio.com', image]);
  assert.equal(result.status, 1); assert.match(result.stderr, /INVALID_MQTT_CONFIGURATION/);
});
