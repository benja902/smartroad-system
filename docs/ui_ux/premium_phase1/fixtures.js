/* Independent design fixtures. Never imported by Flutter or any repository. */
(function(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.UrbesFixtures = factory();
})(globalThis, function() {
  'use strict';
  const vehicle = Object.freeze({ name: 'Toyota Corolla', year: '2024', plate: 'URB-001' });
  const position = Object.freeze({ latitude: -12.05000, longitude: -77.04000, fix: true, fixAgeS: 18 });
  const event = Object.freeze({
    type: 'crash', severity: 'grave', queued: false, acknowledged: false,
    cancelledBySeq: null, ts: '2026-10-13T09:39:00-05:00',
    receivedAt: '2026-10-13T09:41:00-05:00', position,
  });
  function classify(value) {
    if (!['crash', 'rollover', 'sos', 'cancel'].includes(value.type)) return 'technical';
    if (value.type === 'cancel') return 'cancellation';
    if (value.cancelledBySeq != null) return 'cancelled';
    if (value.acknowledged) return 'attended';
    if (value.queued) return 'deferred';
    if (value.type === 'sos' || value.severity === 'grave') return 'activeEmergency';
    if (value.severity === 'moderado') return 'attention';
    return 'informative';
  }
  function locationCopy(value) {
    if (!value) return {
      title: 'Ubicación no disponible', coordinates: null,
      quality: 'El evento recibido no incluye una posición GNSS.', tone: 'neutral',
    };
    const coordinates = `${value.latitude.toFixed(5)}, ${value.longitude.toFixed(5)}`;
    if (!value.fix) return {
      title: 'Última posición conocida', coordinates,
      quality: value.fixAgeS == null ? 'Sin fix al registrar el evento. Antigüedad no disponible.'
        : `Sin fix al registrar el evento. Antigüedad: ${value.fixAgeS} s.`, tone: 'attention',
    };
    return {
      title: 'Ubicación del incidente', coordinates,
      quality: value.fixAgeS == null ? 'GNSS con fix al registrar el evento. Antigüedad no disponible.'
        : `GNSS con fix. Posición de ${value.fixAgeS} s antes del evento.`, tone: 'neutral',
    };
  }
  function clock(iso) {
    if (!iso || Number.isNaN(Date.parse(iso))) return 'No disponible';
    return new Intl.DateTimeFormat('es-PE', {
      timeZone: 'America/Lima', hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
    }).format(new Date(iso));
  }
  function criticalExample(type, scenario) {
    const value = { ...event, type };
    if (scenario === 'noLocation') value.position = null;
    if (scenario === 'lastLocation') value.position = { ...position, fix: false, fixAgeS: 420 };
    if (scenario === 'noTime') value.ts = null;
    if (scenario === 'deferred') value.queued = true;
    if (scenario === 'cancelled') value.cancelledBySeq = 8;
    if (scenario === 'acknowledged') value.acknowledged = true;
    return value;
  }
  return Object.freeze({ vehicle, position, event, classify, locationCopy, clock, criticalExample });
});
