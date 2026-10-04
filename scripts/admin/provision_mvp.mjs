import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { ProvisionError, runProvision } from './provision_mvp_core.mjs';

// Reutilizar la dependencia instalada; no importar ni arrancar el bridge.
const requireSdk = createRequire(new URL('../../bridge/package.json', import.meta.url));
let app;
try {
  const args = process.argv.slice(2), options = {};
  for (let index = 0; index < args.length; index++) {
    const flag = args[index];
    if (flag === '--apply' || flag === '--existing') {
      if (options[flag]) throw new ProvisionError('INVALID_ARGUMENTS');
      options[flag] = true;
    } else if (flag === '--input' || flag === '--confirmed-device-suffix') {
      if (options[flag] !== undefined || !args[index + 1] || args[index + 1].startsWith('--')) throw new ProvisionError('INVALID_ARGUMENTS');
      options[flag] = args[++index];
    } else throw new ProvisionError('INVALID_ARGUMENTS');
  }
  if (Boolean(options['--existing']) === Boolean(options['--input'])
    || Boolean(options['--existing']) !== Boolean(options['--confirmed-device-suffix'])) throw new ProvisionError('SELECTION_REQUIRED');

  const base = new URL(process.env.DATABASE_URL);
  const flutterConfig = readFileSync(new URL('../../lib/firebase_options.dart', import.meta.url), 'utf8');
  const configuredUrls = [...flutterConfig.matchAll(/databaseURL:\s*['"]([^'"]+)['"]/g)].map(match => new URL(match[1]).origin);
  if (base.protocol !== 'https:' || base.pathname !== '/' || base.search || base.hash
    || base.username || base.password || !configuredUrls.includes(base.origin)) throw new ProvisionError('DATABASE_TARGET_MISMATCH');

  const { initializeApp, applicationDefault, deleteApp } = requireSdk('firebase-admin/app');
  const { getAuth } = requireSdk('firebase-admin/auth');
  app = initializeApp({ credential: applicationDefault(), databaseURL: base.href });
  async function databaseRequest(path, method = 'GET', body) {
    const { access_token } = await app.options.credential.getAccessToken();
    const response = await fetch(new URL(`${path}.json`, base), {
      method, headers: { Authorization: `Bearer ${access_token}`, 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) throw new ProvisionError(method === 'GET' ? 'DATABASE_READ_FAILED' : 'DATABASE_UPDATE_FAILED');
    return response.json();
  }
  const adapter = {
    async readSnapshot() {
      const nodes = ['users', 'vehicles', 'devices', 'deviceRegistry', 'vehicleContacts'];
      const values = await Promise.all(nodes.map(node => databaseRequest(node)));
      return Object.fromEntries(nodes.map((node, index) => [node, values[index] ?? {}]));
    },
    async verifyUsers(ids) {
      const result = {};
      for (const uid of ids) {
        try {
          const user = await getAuth(app).getUser(uid);
          result[uid] = { exists: true, disabled: user.disabled };
        } catch { throw new ProvisionError('AUTH_VERIFICATION_FAILED'); }
      }
      return result;
    },
    // PATCH multipath: solo campos del plan, nunca reemplazos de nodos.
    async updateFields(patch) { await databaseRequest('', 'PATCH', patch); },
  };
  const request = options['--input'] ? JSON.parse(readFileSync(options['--input'], 'utf8')) : undefined;
  console.log(options['--apply'] ? 'APPLY: modo explícito; revalidación antes de escribir.' : 'DRY-RUN: solo lecturas RTDB/Auth; ninguna escritura.');
  const heartbeat = setInterval(() => console.log('PROGRESS: validando provisión administrativa.'), 10000);
  try {
    console.log(JSON.stringify(await runProvision(adapter, {
      request, confirmedSuffix: options['--confirmed-device-suffix'], apply: options['--apply'] === true,
    }), null, 2));
  } finally { clearInterval(heartbeat); }
  await deleteApp(app);
  app = undefined;
} catch (error) {
  console.error('PROVISION_ABORTED:', error instanceof ProvisionError ? error.code : 'CONFIGURATION_OR_OPERATION_FAILED');
  process.exitCode = 1;
} finally {
  if (app) await requireSdk('firebase-admin/app').deleteApp(app);
}
