// Puente MQTT -> Firebase Realtime Database para el equipo SDA.
//
// Mantiene una única conexión MQTT persistente al broker (HiveMQ Cloud),
// escribe en Realtime Database con el contrato de docs/device_contract.md,
// y proyecta las cancelaciones sobre el original mediante transacciones para
// que funcionen sin importar el orden de llegada. No implementa `comandos`
// (ping/position/diag on-demand) — queda fuera del MVP.
//
// Requiere una cuenta de servicio con permiso de escritura en Realtime
// Database (bypassa las reglas de seguridad, igual que el Admin SDK).
import { loadEnvFile } from 'node:process';

import mqtt from 'mqtt';
import http from 'node:http';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getDatabase, ServerValue } from 'firebase-admin/database';
import {
  CancellationProjectionError, ingestMqttEvent, reconcileStoredCancellations,
  reconcileCriticalReadIndex,
  reconcileChronologicalReadIndex,
} from './event_writer.js';
import { MqttEventValidationError } from './mqtt_event_normalizer.js';
import { AssociationLookupError, resolveAssociation } from './association_resolver.js';
// Carga las variables locales desde .env
loadEnvFile('.env');
const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error('Falta la variable de entorno DATABASE_URL (URL de tu Realtime Database).');
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), databaseURL: DATABASE_URL });
const db = getDatabase();

let recoveryTimer;
async function recoverCancellations() {
  recoveryTimer = undefined;
  try {
    await reconcileStoredCancellations(db, {
      reportDiagnostic: (code) => console.warn('diagnóstico MQTT:', code),
    });
    await reconcileCriticalReadIndex(db);
    await reconcileChronologicalReadIndex(db);
  } catch (error) {
    console.error('conciliación de eventos fallida:', error.name);
    scheduleCancellationRecovery();
  }
}

function scheduleCancellationRecovery() {
  if (recoveryTimer) return;
  recoveryTimer = setTimeout(recoverCancellations, 30000);
}

// Recupera cancelaciones pendientes y el índice de lectura a partir de events.
// No depende de que el broker vuelva a entregar un mensaje.
void recoverCancellations();

const PREFIX = process.env.MQTT_PREFIX ?? 'sda';
const HOST = process.env.MQTT_HOST;
const USER = process.env.MQTT_USER ?? 'lilygo';
const PASS = process.env.MQTT_PASS;

if (!HOST || !PASS) {
  console.error('Faltan MQTT_HOST y/o MQTT_PASS.');
  process.exit(1);
}

// clean:false solicita una sesión persistente al broker. El PUBACK del cliente
// MQTT no espera a que termine este listener asíncrono ni la escritura RTDB.
const cliente = mqtt.connect(`mqtts://${HOST}:8883`, {
  clientId: 'puente-urbes-sda-1',
  username: USER,
  password: PASS,
  clean: false,
  keepalive: 60,
  reconnectPeriod: 5000,
  rejectUnauthorized: true,
});

cliente.on('connect', () => {
  cliente.subscribe(
    [`${PREFIX}/+/event`, `${PREFIX}/+/status`, `${PREFIX}/+/position`, `${PREFIX}/+/availability`],
    { qos: 1 },
  );
  console.log('puente conectado al broker MQTT');
});

cliente.on('error', (e) => console.error('mqtt error:', e.message));
cliente.on('reconnect', () => console.log('mqtt reconectando...'));

cliente.on('message', async (topico, cuerpo) => {
  const partes = topico.split('/');
  const deviceId = partes[1];
  const hoja = partes.slice(2).join('/');

  try {
    if (hoja === 'availability') {
      await db.ref(`devices/${deviceId}`).update({
        online: cuerpo.toString() === 'online',
        lastSeen: ServerValue.TIMESTAMP,
      });
      return;
    }

    if (hoja === 'event') {
      const { written } = await ingestMqttEvent(topico, cuerpo, {
        db, resolveAssociation: (id) => resolveAssociation(db, id),
        serverTimestamp: ServerValue.TIMESTAMP,
        scheduleRecovery: scheduleCancellationRecovery,
        prefix: PREFIX, reportDiagnostic: (code) => console.warn('diagnóstico MQTT:', code),
      });
      console.log(written ? 'evento guardado' : 'evento duplicado');
      return;
    }

    const datos = JSON.parse(cuerpo.toString());

    if (hoja === 'status') {
      // El payload de `status` ya usa exactamente los mismos nombres de
      // campo top-level que espera DeviceStatus.fromJson (state, fw,
      // sensors, inputs, outputs, sd, modem, gnss, power, system) — se
      // reenvía tal cual, sin transformar.
      const { id, ts, ...resto } = datos;
      await db.ref(`devices/${deviceId}`).update({ ...resto, lastSeen: ServerValue.TIMESTAMP });
    } else if (hoja === 'position') {
      await db.ref(`devices/${deviceId}`).update({ gnss: datos.position, lastSeen: ServerValue.TIMESTAMP });
    }
  } catch (e) {
    if (e instanceof MqttEventValidationError) {
      console.warn('mensaje MQTT inválido:', e.code);
    } else if (e instanceof CancellationProjectionError) {
      console.error('proyección de cancelación fallida; conciliación programada');
      scheduleCancellationRecovery();
    } else if (e instanceof AssociationLookupError) {
      console.error('consulta administrativa fallida:', e.code);
    } else {
      console.error('procesamiento MQTT fallido:', e.name);
    }
  }
});

// Sonda de salud para Cloud Run.
http
  .createServer((req, res) => {
    res.writeHead(cliente.connected ? 200 : 503).end();
  })
  .listen(process.env.PORT ?? 8080);
