import { existsSync, accessSync, statSync, constants } from 'node:fs';
import { loadEnvFile } from 'node:process';
import { initializeApp, applicationDefault, deleteApp } from 'firebase-admin/app';
import { getDatabase } from 'firebase-admin/database';
import { getAuth } from 'firebase-admin/auth';
import { readBackendConfig, startBackend } from './backend.js';

// Preserve the local bridge workflow. Compose injects configuration and mounts credentials.
let app, backend;
try {
  if ((process.env.BACKEND_DEPLOYMENT ?? 'local') === 'local' && existsSync('.env')) loadEnvFile('.env');
  const config = readBackendConfig();
  if (config.deployment === 'compose') {
    try {
      accessSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, constants.R_OK);
      if (!statSync(process.env.GOOGLE_APPLICATION_CREDENTIALS).isFile()) throw Error();
    } catch { throw Object.assign(new Error(), { name: 'BackendConfigurationError', code: 'EXTERNAL_CREDENTIALS_UNREADABLE' }); }
  }
  app = initializeApp({ credential: applicationDefault(), databaseURL: config.databaseURL,
    ...(config.projectId ? { projectId: config.projectId } : {}),
  });
  backend = await startBackend({ config, db: getDatabase(app), auth: getAuth(app) });
  console.log('backend listo:', config.mode);
  let stopping = false;
  const shutdown = async () => {
    if (stopping) return;
    stopping = true;
    try { await backend.stop(); await deleteApp(app); }
    catch { process.exitCode = 1; }
  };
  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
} catch (error) {
  console.error('BACKEND_START_FAILED:', error?.code?.startsWith('INVALID_') ||
    error?.name === 'BackendConfigurationError' ? error.code : 'CONFIGURATION_OR_STARTUP_FAILED');
  if (app) await deleteApp(app).catch(() => {});
  process.exitCode = 1;
}
