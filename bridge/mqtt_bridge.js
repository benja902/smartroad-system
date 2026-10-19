import mqtt from 'mqtt';
import { ServerValue } from 'firebase-admin/database';
import {
  CancellationProjectionError, ingestMqttEvent, reconcileStoredCancellations,
  reconcileCriticalReadIndex,
  reconcileChronologicalReadIndex,
} from './event_writer.js';
import { MqttEventValidationError } from './mqtt_event_normalizer.js';
import { AssociationLookupError, resolveAssociation } from './association_resolver.js';

// Imported only in mqtt-bridge mode. No connection is created on import.
export function startMqttBridge({ db, config, scheduleRecovery, connect = mqtt.connect }) {
  async function recoverIncidents() {
    try {
      await reconcileStoredCancellations(db, {
        reportDiagnostic: (code) => console.warn('diagnostico MQTT:', code),
        serverTimestamp: ServerValue.TIMESTAMP,
      });
      await reconcileCriticalReadIndex(db);
      await reconcileChronologicalReadIndex(db);
    } catch (error) {
      console.error('conciliacion de eventos fallida:', error.name);
      scheduleRecovery();
    }
  }

  const { prefix: PREFIX, host: HOST, user: USER, password: PASS } = config.mqtt;

  // clean:false solicita una sesión persistente al broker. El PUBACK del cliente
  // MQTT no espera a que termine este listener asíncrono ni la escritura RTDB.
  const cliente = connect(`mqtts://${HOST}:8883`, {
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
          scheduleRecovery: scheduleRecovery,
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
        scheduleRecovery();
      } else if (e instanceof AssociationLookupError) {
        console.error('consulta administrativa fallida:', e.code);
      } else {
        console.error('procesamiento MQTT fallido:', e.name);
      }
    }
  });

  return { client: cliente, recoverIncidents };
}
