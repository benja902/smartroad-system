// Escritura de eventos con dependencias explícitas: este módulo no inicia
// MQTT, no carga .env y no inicializa Firebase al importarse.
export async function persistEvent(deviceId, ev, { db, resolveAssociation, serverTimestamp }) {
  const association = await resolveAssociation(deviceId);
  const userId = association?.userId ?? null;
  const dedupKey = `${deviceId}_${ev.seq}`;
  const ref = db.ref(`events/${dedupKey}`);

  // Un cambio de ts no demuestra reutilización de seq y no debe borrar
  // cancelaciones ni reconocimientos históricos. La política ante una
  // colisión real de seq se definirá en la Fase 2.
  // vehicleId siempre procede de la asociación administrativa. Cualquier
  // campo homónimo recibido en el payload MQTT se descarta.
  const eventPayload = { ...ev };
  delete eventPayload.vehicleId;
  // Estos estados pertenecen al backend o a la app, nunca al payload SDA.
  delete eventPayload.acknowledged;
  delete eventPayload.cancelledBySeq;
  delete eventPayload.cancelledAt;
  const actualizacion = { ...eventPayload, userId, receivedAt: serverTimestamp };
  if (association?.vehicleId) actualizacion.vehicleId = association.vehicleId;

  // update(), no set(): escritura de fusión — si una cancelación
  // desordenada ya proyectó cancelledBySeq/cancelledAt sobre esta misma
  // clave, no se pisa.
  await ref.update(actualizacion);

  if (ev.type === 'cancel' && typeof ev.cancels_seq === 'number') {
    const originalKey = `${deviceId}_${ev.cancels_seq}`;
    await db.ref(`events/${originalKey}`).update({
      cancelledBySeq: ev.seq,
      cancelledAt: serverTimestamp,
    });
  }

  return { dedupKey, userId };
}
