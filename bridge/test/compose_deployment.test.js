import assert from 'node:assert/strict';
import test from 'node:test';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { generateKeyPairSync, X509Certificate } from 'node:crypto';

// Integration is local-only: generated RSA fixture, internal Docker network, local CA.
// Nothing here starts MQTT, reaches Firebase or requests a public certificate.
function docker(args, env) {
  const r = spawnSync('docker', ['--context', 'desktop-linux', ...args], {
    env: { ...process.env, ...env }, encoding: 'utf8', windowsHide: true, timeout: 55000,
  });
  assert.ifError(r.error);
  assert.equal(r.status, 0, r.stderr || 'Docker command failed');
  return r.stdout.trim();
}
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function eventually(fn, attempts = 35) {
  let error;
  for (let i = 0; i < attempts; i++) {
    try { return await fn(); } catch (e) { error = e; await delay(400); }
  }
  throw error;
}

test('Compose: private API, default-off MQTT, trusted TLS, restart and persistent certificate/config', { timeout: 180000 }, async () => {
  const temp = await mkdtemp(join(tmpdir(), 'urbes-compose-fixture-'));
  const project = `urbes-fixture-${process.pid}`;
  const composePath = resolve('bridge/deploy/compose.yaml');
  const productionCaddy = await readFile('bridge/deploy/Caddyfile', 'utf8');
  const caddyPath = join(temp, 'Caddyfile');
  await writeFile(caddyPath, '{\n local_certs\n}\n' + productionCaddy);
  const credentials = join(temp, 'fixture.json');
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  await writeFile(credentials, JSON.stringify({ type: 'service_account', project_id: 'demo-compose-fixture',
    private_key_id: 'fixture-only', private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
    client_email: 'fixture@demo-compose-fixture.iam.gserviceaccount.com',
    client_id: '1234567890', token_uri: 'https://oauth2.googleapis.com/token' }));
  const override = join(temp, 'isolated.yaml');
  await writeFile(override, 'networks:\n  proxy:\n    internal: true\n');
  const env = { PUBLIC_DOMAIN: 'api.example.test', FIREBASE_PROJECT_ID: 'demo-compose-fixture',
    DATABASE_URL: 'https://demo-compose-fixture-default-rtdb.firebaseio.com',
    FIREBASE_CREDENTIALS_FILE: credentials, CADDYFILE_PATH: caddyPath,
    CADDY_BIND_ADDRESS: '127.0.0.1', HTTP_PORT: '0', HTTPS_PORT: '0',
    CONTACT_OPERATIONS_ENABLED: 'false', URBES_IMAGE: 'urbes-backend:local',
    PROXY_IP: '172.30.43.2', API_IP: '172.30.43.3', PROXY_SUBNET: '172.30.43.0/24',
    MQTT_ENV_FILE: join(temp, 'not-provisioned.env') };
  const base = ['compose', '-p', project, '-f', composePath, '-f', override];
  const compose = (...args) => docker([...base, ...args], env);
  const id = service => compose('ps', '-q', service);
  const inspect = service => JSON.parse(docker(['inspect', id(service)], env))[0];
  let started = false;
  try {
    const config = JSON.parse(compose('--profile', 'mqtt', 'config', '--format', 'json'));
    assert.equal(config.services['http-api'].image, config.services['mqtt-bridge'].image);
    assert.deepEqual(config.services['mqtt-bridge'].profiles, ['mqtt']);
    assert.equal(config.services['http-api'].ports, undefined);
    assert.equal(config.services['mqtt-bridge'].ports, undefined);
    assert.equal(config.services['http-api'].environment.CONTACT_OPERATIONS_ENABLED, 'false');
    assert.equal(config.services['http-api'].environment.MQTT_PASS, undefined);
    assert.equal(config.services['http-api'].restart, 'unless-stopped');
    assert.equal(config.services['http-api'].logging.options['max-file'], '3');
    assert.equal(config.services.caddy.image.includes('@sha256:'), true);
    assert.equal(config.networks.proxy.internal, true);
    assert.equal(config.services.caddy.volumes.filter(v => v.type === 'volume').length, 2);
    console.log('Compose configuration: default-off MQTT, no API port, external secret, persistent TLS.');
    started = true;
    compose('up', '-d', '--wait', '--wait-timeout', '45');
    assert.deepEqual(compose('ps', '--services').split(/\r?\n/).sort(), ['caddy', 'http-api']);
    const api = inspect('http-api');
    assert.deepEqual(api.HostConfig.PortBindings, {});
    assert.equal(api.Mounts.find(m => m.Destination === '/run/secrets/firebase_admin').RW, false);
    assert.equal(api.HostConfig.RestartPolicy.Name, 'unless-stopped');
    const root = await eventually(() => docker(['exec', id('caddy'), 'cat', '/data/caddy/pki/authorities/local/root.crt'], env));
    async function request(path, headers = {}) {
      // Probe inside the isolated network: no external connectivity or disabled TLS checks.
      const code = `const https=require('node:https');
        const req=https.request({hostname:${JSON.stringify(env.PROXY_IP)},port:443,agent:false,
          servername:'api.example.test',ca:${JSON.stringify(root)},path:${JSON.stringify(path)},
          method:${JSON.stringify(path.startsWith('/contacts/') ? 'POST' : 'GET')},
          headers:${JSON.stringify({ Host: 'api.example.test', ...headers })},timeout:5000},res=>{
          const fingerprint=res.socket.getPeerCertificate().fingerprint256;
          res.resume();res.on('end',()=>console.log(JSON.stringify({status:res.statusCode,fingerprint})));});
        req.on('error',()=>process.exit(1));req.on('timeout',()=>req.destroy());req.end();`;
      return JSON.parse(docker(['exec', id('http-api'), 'node', '-e', code], env));
    }
    const first = await eventually(async () => { const r = await request('/healthz'); assert.equal(r.status, 200); return r; });
    assert.equal((await request('/contacts/accept', { 'X-Forwarded-Proto': 'https', Authorization: 'Bearer fixture' })).status, 503);
    const configBefore = docker(['exec', id('caddy'), 'cat', '/config/caddy/autosave.json'], env);
    assert.match(configBefore, /api\.example\.test/);
    // Read-only proxy config survives container recreation; both named volumes survive.
    compose('up', '-d', '--force-recreate', '--wait', '--wait-timeout', '45', 'caddy');
    const rootAfter = docker(['exec', id('caddy'), 'cat', '/data/caddy/pki/authorities/local/root.crt'], env);
    assert.equal(new X509Certificate(rootAfter).fingerprint256, new X509Certificate(root).fingerprint256);
    const after = await eventually(async () => { const r = await request('/healthz'); assert.equal(r.status, 200); return r; });
    assert.equal(after.fingerprint, first.fingerprint);
    assert.equal(docker(['exec', id('caddy'), 'cat', '/config/caddy/autosave.json'], env), configBefore);
    console.log('TLS verified with fixture CA; certificate and configuration survive recreation.');
    const apiId = id('http-api');
    // Simulate application failure, not a deliberate Docker stop/kill (which suppresses restart).
    docker(['exec', apiId, 'sh', '-c', 'kill -KILL $(pidof node)'], env);
    await eventually(() => {
      const state = inspect('http-api'); assert.ok(state.RestartCount >= 1);
      assert.equal(state.State.Running, true);
    });
    await eventually(async () => assert.equal((await request('/readyz')).status, 200));
    console.log('API automatically restarted after process failure; HTTPS health restored.');
  } finally {
    if (started) compose('down', '--volumes', '--remove-orphans');
    // Generated fixture files remain in OS temp for diagnostics, never in the repository/image.
  }
});

test('Compose entrypoint fails closed when the external credential file is absent', () => {
  const r = spawnSync('docker', ['--context', 'desktop-linux', 'run', '--rm', '--network', 'none',
    '-e', 'BACKEND_MODE=http-api', '-e', 'BACKEND_DEPLOYMENT=compose',
    '-e', 'FIREBASE_PROJECT_ID=demo-compose-fixture',
    '-e', 'DATABASE_URL=https://demo-compose-fixture-default-rtdb.firebaseio.com',
    '-e', 'HTTP_TRUST_PROXY_IP=172.30.43.2', '-e', 'CONTACT_PUBLIC_URL=https://api.example.test',
    '-e', 'GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/absent', 'urbes-backend:local'],
  { encoding: 'utf8', timeout: 15000, windowsHide: true });
  assert.ifError(r.error); assert.equal(r.status, 1); assert.match(r.stderr, /EXTERNAL_CREDENTIALS_UNREADABLE/);
});
