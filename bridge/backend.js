import http from 'node:http';
import { isIP } from 'node:net';
import { createContactHandler, createContactRecovery, reconcileContactIndexes } from './contact_operations.js';

export class BackendConfigurationError extends Error {
  constructor(code) { super(code); this.name = 'BackendConfigurationError'; this.code = code; }
}
const reject = code => { throw new BackendConfigurationError(code); };
const boolean = (value, code) => {
  if (value === undefined || value === 'false') return false;
  if (value === 'true') return true;
  return reject(code);
};
export function readBackendConfig(env = process.env) {
  const deployment = env.BACKEND_DEPLOYMENT ?? 'local';
  if (!['local', 'compose'].includes(deployment)) reject('INVALID_BACKEND_DEPLOYMENT');
  if (deployment === 'compose' && !env.BACKEND_MODE) reject('BACKEND_MODE_REQUIRED_IN_COMPOSE');
  const mode = env.BACKEND_MODE ?? 'mqtt-bridge';
  if (!['mqtt-bridge', 'http-api'].includes(mode)) reject('INVALID_BACKEND_MODE');
  const rawPort = env.PORT ?? '8080';
  if (!/^\d+$/.test(rawPort) || Number(rawPort) < 1 || Number(rawPort) > 65535) reject('INVALID_PORT');
  let databaseURL;
  try { databaseURL = new URL(env.DATABASE_URL); } catch { reject('INVALID_DATABASE_URL'); }
  if (databaseURL.protocol !== 'https:' || databaseURL.pathname !== '/' || databaseURL.search ||
      databaseURL.hash || databaseURL.username || databaseURL.password ||
      !(databaseURL.hostname.endsWith('.firebaseio.com') || databaseURL.hostname.endsWith('.firebasedatabase.app'))) {
    reject('INVALID_DATABASE_URL');
  }
  const projects = [env.FIREBASE_PROJECT_ID, env.GCLOUD_PROJECT, env.GOOGLE_CLOUD_PROJECT].filter(Boolean);
  if (projects.some(id => !/^[a-z][a-z0-9-]{4,62}$/.test(id)) || new Set(projects).size > 1) reject('INVALID_PROJECT_ID');
  const projectId = projects[0];
  if (mode === 'http-api' && !projectId) reject('PROJECT_ID_REQUIRED');
  const databaseEmulator = env.FIREBASE_DATABASE_EMULATOR_HOST;
  const authEmulator = env.FIREBASE_AUTH_EMULATOR_HOST;
  const anyEmulator = !!(databaseEmulator || authEmulator);
  if (anyEmulator && (deployment === 'compose' || !projectId?.startsWith('demo-') ||
      databaseEmulator !== '127.0.0.1:19000' ||
      (authEmulator !== undefined && authEmulator !== '127.0.0.1:19099'))) reject('INVALID_EMULATOR_CONFIGURATION');
  const localEmulator = anyEmulator && authEmulator === '127.0.0.1:19099';
  if (mode === 'http-api' && anyEmulator && !localEmulator) reject('BOTH_EMULATORS_REQUIRED');
  const realOperations = boolean(env.CONTACT_OPERATIONS_ENABLED, 'INVALID_CONTACT_OPERATIONS_FLAG');
  if (realOperations && (mode !== 'http-api' || anyEmulator || projectId?.startsWith('demo-') ||
      deployment !== 'compose')) reject('REAL_OPERATIONS_REQUIRE_COMPOSE');
  if (deployment === 'compose' && !env.GOOGLE_APPLICATION_CREDENTIALS?.startsWith('/')) {
    reject('EXTERNAL_CREDENTIALS_REQUIRED');
  }
  let trustedProxyIp;
  if (deployment === 'compose' && mode === 'http-api') {
    trustedProxyIp = env.HTTP_TRUST_PROXY_IP;
    // One explicit private IPv4 peer, not a forwarded client IP or arbitrary subnet.
    const parts = trustedProxyIp?.split('.').map(Number);
    if (isIP(trustedProxyIp ?? '') !== 4 || !(parts[0] === 10 ||
        (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) ||
        (parts[0] === 192 && parts[1] === 168))) reject('INVALID_TRUSTED_PROXY_IP');
  }
  let publicHost;
  if (deployment === 'compose' && mode === 'http-api') {
    let url;
    try { url = new URL(env.CONTACT_PUBLIC_URL); } catch { reject('INVALID_PUBLIC_HTTPS_URL'); }
    if (url.protocol !== 'https:' || isIP(url.hostname) || !url.hostname.includes('.') || url.hostname.length > 253 ||
        !url.hostname.split('.').every(label => /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/i.test(label)) || url.port ||
        url.username || url.password || url.pathname !== '/' || url.search || url.hash) reject('INVALID_PUBLIC_HTTPS_URL');
    publicHost = url.host;
  }
  let mqtt;
  if (mode === 'mqtt-bridge') {
    const host = env.MQTT_HOST;
    if (!host || !/^[a-zA-Z0-9.-]+$/.test(host) || !env.MQTT_PASS ||
        (env.MQTT_USER !== undefined && !env.MQTT_USER.trim())) reject('INVALID_MQTT_CONFIGURATION');
    const prefix = env.MQTT_PREFIX ?? 'sda';
    if (!prefix || /[+#\x00-\x1f\x7f]/.test(prefix) || prefix.includes('/')) reject('INVALID_MQTT_PREFIX');
    mqtt = { host, password: env.MQTT_PASS, user: env.MQTT_USER ?? 'lilygo', prefix };
  }
  return { mode, deployment, port: Number(rawPort), databaseURL: databaseURL.href, projectId,
    localEmulator: mode === 'http-api' && localEmulator,
    realOperations, publicHost, trustedProxyIp, mqtt };
}

// Runtime wiring only. No Firebase credentials or network clients are created here.
export async function startBackend({ config, db, auth, connectMqtt,
  loadMqtt = () => import('./mqtt_bridge.js') }) {
  let recoveryTimer, stopped = false, mqtt;
  const contactsEnabled = config.mode === 'http-api' && (config.localEmulator || config.realOperations);
  function scheduleRecovery() {
    if (!stopped && !recoveryTimer) {
      recoveryTimer = setTimeout(recover, 30000);
      recoveryTimer.unref();
    }
  }
  const recoverContacts = createContactRecovery({
    enabled: contactsEnabled, reconcile: () => reconcileContactIndexes(db), scheduleRecovery,
  });
  async function recover() {
    recoveryTimer = undefined;
    if (stopped) return;
    if (config.mode === 'http-api') await recoverContacts();
    else await mqtt.recoverIncidents();
  }
  if (config.mode === 'mqtt-bridge') {
    const { startMqttBridge } = await loadMqtt();
    mqtt = startMqttBridge({ db, config, scheduleRecovery, connect: connectMqtt });
  }
  const handler = createContactHandler({ db, auth,
    health: () => !stopped && (config.mode === 'http-api' || mqtt.client.connected),
    scheduleRecovery, localEmulator: config.localEmulator,
    realOperations: config.realOperations, publicHost: config.publicHost, trustedProxyIp: config.trustedProxyIp,
  });
  const server = http.createServer((req, res) => {
    // Explicit health paths use the existing health behavior, never an MQTT dependency in API mode.
    if (req.method === 'GET' && ['/healthz', '/readyz'].includes(req.url)) req.url = '/';
    void handler(req, res);
  });
  server.requestTimeout = 30000;
  server.headersTimeout = 15000;
  async function stop() {
    stopped = true;
    clearTimeout(recoveryTimer);
    await Promise.all([
      new Promise(resolve => { if (server.listening) server.close(resolve); else resolve(); }),
      mqtt ? mqtt.client.endAsync() : Promise.resolve(),
    ]);
  }
  try {
    await new Promise((resolve, reject) => {
      server.once('error', reject);
      server.listen(config.port, '0.0.0.0', resolve);
    });
  } catch (error) { await stop(); throw error; }
  void recover();
  return { server, stop, client: mqtt?.client };
}
