// Puente MQTT -> Firebase Realtime Database para el equipo SDA.
//
// Mantiene una única conexión MQTT persistente al broker (HiveMQ Cloud),
// escribe en Realtime Database exactamente con el shape descrito en
// docs/device_contract.md, y proyecta las cancelaciones sobre el evento
// original mediante escrituras de fusión (update, no set) para que
// funcionen sin importar el orden de llegada. No implementa `comandos`
// (ping/position/diag on-demand) — queda fuera del MVP.
//
// Requiere una cuenta de servicio con permiso de escritura en Realtime
// Database (bypassa las reglas de seguridad, igual que el Admin SDK).

import mqtt from 'mqtt';
import http from 'node:http';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getDatabase, ServerValue } from 'firebase-admin/database';

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error('Falta la variable de entorno DATABASE_URL (URL de tu Realtime Database).');
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), databaseURL: DATABASE_URL });
const db = getDatabase();

const PREFIX = process.env.MQTT_PREFIX ?? 'sda';
const HOST = process.env.MQTT_HOST;
const USER = process.env.MQTT_USER ?? 'lilygo';
const PASS = process.env.MQTT_PASS;

if (!HOST || !PASS) {
  console.error('Faltan MQTT_HOST y/o MQTT_PASS.');
  process.exit(1);
}

// clean:false + clientId fijo: el broker retiene los mensajes QoS 1
// publicados mientras el puente estuvo caído y los entrega al reconectar.
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

// Cache en memoria: deviceId -> { vehicleId, userId }. Evita una consulta
// a vehicles/ por cada evento; se refresca si no se encuentra.
const associationCache = new Map();

async function resolveAssociation(deviceId) {
  if (associationCache.has(deviceId)) return associationCache.get(deviceId);

  const snapshot = await db
    .ref('vehicles')
    .orderByChild('deviceId')
    .equalTo(deviceId)
    .limitToFirst(1)
    .get();

  if (!snapshot.exists()) {
    console.warn(`sin vehículo registrado para deviceId=${deviceId}, evento sin asociación`);
    return null;
  }

  const [[vehicleId, vehicle]] = Object.entries(snapshot.val());
  const association = { vehicleId, userId: vehicle.ownerId ?? null };
  associationCache.set(deviceId, association);
  return association;
}

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
    } else if (hoja === 'event') {
      await guardarEvento(deviceId, datos);
    }
  } catch (e) {
    console.error('mensaje descartado', topico, e.message);
  }
});

async function guardarEvento(deviceId, ev) {
  const association = await resolveAssociation(deviceId);
  const userId = association?.userId ?? null;
  const dedupKey = `${deviceId}_${ev.seq}`;
  const ref = db.ref(`events/${dedupKey}`);

  // El contador `seq` del equipo puede reiniciarse (p. ej. tras apagar y
  // encender), así que una clave deviceId_seq puede recibir un evento
  // real distinto al que ocupó esa clave antes. update() sin más fusionaría
  // acknowledged/cancelledBySeq/cancelledAt viejos sobre el evento nuevo,
  // ocultando una alerta real. Si el nodo existente tiene un `ts` distinto
  // al que llega ahora, es un evento distinto reutilizando la clave: se
  // limpian esos campos antes de fusionar. Si el `ts` coincide (o ambos
  // son null), es una reentrega del mismo evento y esos campos se
  // conservan tal cual.
  // vehicleId siempre procede de la asociación administrativa. Cualquier
  // campo homónimo recibido en el payload MQTT se descarta.
  const eventPayload = { ...ev };
  delete eventPayload.vehicleId;
  const actualizacion = { ...eventPayload, userId, receivedAt: ServerValue.TIMESTAMP };
  if (association?.vehicleId) actualizacion.vehicleId = association.vehicleId;
  if (ev.type === 'crash' || ev.type === 'rollover' || ev.type === 'sos') {
    const existente = (await ref.get()).val();
    if (existente && existente.ts !== (ev.ts ?? null)) {
      actualizacion.acknowledged = false;
      actualizacion.cancelledBySeq = null;
      actualizacion.cancelledAt = null;
    }
  }

  // update(), no set(): escritura de fusión — si una cancelación
  // desordenada ya proyectó cancelledBySeq/cancelledAt sobre esta misma
  // clave, no se pisa.
  await ref.update(actualizacion);

  if (ev.type === 'cancel' && typeof ev.cancels_seq === 'number') {
    const originalKey = `${deviceId}_${ev.cancels_seq}`;
    await db.ref(`events/${originalKey}`).update({
      cancelledBySeq: ev.seq,
      cancelledAt: ServerValue.TIMESTAMP,
    });
  }

  console.log(`evento guardado: ${dedupKey} (${ev.type}, userId=${userId ?? 'desconocido'})`);
}

// Sonda de salud para Cloud Run.
http
  .createServer((req, res) => {
    res.writeHead(cliente.connected ? 200 : 503).end();
  })
  .listen(process.env.PORT ?? 8080);
