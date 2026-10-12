import assert from 'node:assert/strict';
import test from 'node:test';
import { MqttEventValidationError, normalizeMqttEvent } from '../mqtt_event_normalizer.js';

const topic = 'sda/SDA-TEST/event';
const message = (overrides = {}) => JSON.stringify({ id: 'SDA-TEST', seq: 1, type: 'crash', ...overrides });

function rejects(inputTopic, payload, code) {
  assert.throws(
    () => normalizeMqttEvent(inputTopic, payload),
    (error) => error instanceof MqttEventValidationError && error.code === code,
  );
}

test('A02: accepts a partial original without inventing time, position or severity', () => {
  const result = normalizeMqttEvent(topic, Buffer.from(message({ type: 'rollover' })));
  assert.deepEqual(result, {
    deviceId: 'SDA-TEST',
    kind: 'incident',
    event: { id: 'SDA-TEST', seq: 1, type: 'rollover' },
  });
});

test('A03: rejects malformed JSON, non-object payloads and missing type', () => {
  for (const payload of ['{', 'null', '42', '[]', '"event"']) {
    rejects(topic, payload, payload === '{' ? 'INVALID_JSON' : 'INVALID_PAYLOAD');
  }
  rejects(topic, Buffer.from([0xff]), 'INVALID_JSON');
  rejects(topic, { id: 'SDA-TEST', seq: 1, type: 'crash' }, 'INVALID_JSON');
  rejects(topic, JSON.stringify({ id: 'SDA-TEST', seq: 1 }), 'INVALID_TYPE');
  rejects(topic, message({ type: '  ' }), 'INVALID_TYPE');
});

test('A03: only safe, nonnegative integer seq values can form event keys', () => {
  for (const seq of [null, '1', -1, 1.5, Number.MAX_SAFE_INTEGER + 1]) {
    rejects(topic, message({ seq }), 'INVALID_SEQ');
  }
  assert.equal(normalizeMqttEvent(topic, message({ seq: 0 })).event.seq, 0);
});

test('A04: topic identity must match payload and be safe as an RTDB key', () => {
  rejects(topic, message({ id: 'OTHER' }), 'INVALID_ID');
  rejects('sda/SDA.TEST/event', JSON.stringify({ id: 'SDA.TEST', seq: 1, type: 'sos' }), 'INVALID_TOPIC');
  rejects('sda/SDA-TEST/other', message(), 'INVALID_TOPIC');
  rejects('sda/SDA-TEST/event/extra', message(), 'INVALID_TOPIC');
  rejects(`sda/${'A'.repeat(768)}/event`, JSON.stringify({ id: 'A'.repeat(768), seq: 1, type: 'sos' }), 'INVALID_SEQ');
});

test('A05: unknown type remains diagnostic even when severity is grave', () => {
  const result = normalizeMqttEvent(topic, message({ type: 'future_alarm', severity: 'grave' }));
  assert.equal(result.kind, 'diagnostic');
  assert.equal(result.event.type, 'future_alarm');
  assert.equal(result.event.severity, 'grave');
  assert.equal(normalizeMqttEvent(topic, message({ type: 'booted' })).kind, 'technical');
});

test('C06: cancel must reference a different usable seq; originals cannot claim references', () => {
  for (const cancels_seq of [undefined, null, '1', -1, 1.5, 1]) {
    rejects(topic, message({ seq: 1, type: 'cancel', cancels_seq }), 'INVALID_CANCEL_REFERENCE');
  }
  rejects(topic, message({ cancels_seq: 2 }), 'INVALID_CANCEL_REFERENCE');
  assert.deepEqual(normalizeMqttEvent(topic, message({ seq: 2, type: 'cancel', cancels_seq: 1 })), {
    deviceId: 'SDA-TEST',
    kind: 'cancellation',
    event: { id: 'SDA-TEST', seq: 2, type: 'cancel', cancels_seq: 1 },
  });
});

test('preserves raw firmware time and queued presence without fabricating units or false', () => {
  const raw = normalizeMqttEvent(topic, message({ ts: 0, queued: true, time_src: 'unknown' }));
  assert.equal(raw.event.ts, 0);
  assert.equal(raw.event.queued, true);
  assert.equal(raw.event.time_src, 'unknown');
  const partial = normalizeMqttEvent(topic, message({ ts: '2026-01-01T00:00:00Z' }));
  assert.equal(partial.event.ts, '2026-01-01T00:00:00Z');
  assert.equal(Object.hasOwn(partial.event, 'queued'), false);
});

test('position: accepts absence, null and complete or minimal coordinate fixes', () => {
  for (const position of [undefined, null]) {
    const result = normalizeMqttEvent(topic, message({ position }));
    assert.equal(Object.hasOwn(result.event, 'position'), false);
  }
  for (const position of [
    { lat: 0, lon: 0 },
    { lat: -90, lon: -180 },
    { lat: 90, lon: 180 },
    { lat: 12.345678, lon: -76.54321 },
    { fix: false, lat: -9.930833, lon: -76.241944, fix_age_s: 0 },
    { fix: true, lat: -9.930833, lon: -76.241944, alt_m: 1894,
      speed_kmh: 0, heading: 218, hdop: 1.1, sats: 9, fix_age_s: 3 },
  ]) {
    assert.deepEqual(normalizeMqttEvent(topic, message({ position })).event.position, position);
  }
});

test('position: rejects the reviewer examples and malformed known fields', () => {
  for (const position of [
    { fix: true, lat: 'bad', lon: 1 },
    { fix: true },
    { lat: 1 },
    { lon: 1 },
    { lat: null, lon: 1 },
    { lat: 91, lon: 1 },
    { lat: 1, lon: 181 },
    { lat: 90.00000000000001, lon: 0 },
    { lat: -90.00000000000001, lon: 0 },
    { lat: 0, lon: 180.00000000000003 },
    { lat: 0, lon: -180.00000000000003 },
    { lat: 1, lon: 'bad' },
    { lat: 1, lon: 1, fix: 'true' },
    { lat: 1, lon: 1, sats: 1.5 },
    { lat: 1, lon: 1, fix_age_s: '3' },
    { lat: 1, lon: 1, hdop: '1.1' },
  ]) {
    rejects(topic, message({ position }), 'INVALID_FIELD');
  }
  rejects(topic, '{"id":"SDA-TEST","seq":1,"type":"crash","position":{"lat":1e999,"lon":1}}', 'INVALID_FIELD');
  rejects(topic, '{"id":"SDA-TEST","seq":1,"type":"crash","position":{"lat":1,"lon":1e999}}', 'INVALID_FIELD');
});

test('detection: accepts documented fields and partial measurements', () => {
  for (const detection of [
    {},
    { peak_g: 0, rollover: false },
    { peak_g: 38.4, delta_v_kmh: 24.1, duration_ms: 62, axis_peak: 'y',
      rollover: false, tilt_deg: 12.5, gyro_max_dps: 145 },
  ]) {
    assert.deepEqual(normalizeMqttEvent(topic, message({ detection })).event.detection, detection);
  }
});

test('detection: rejects incorrect types in known fields', () => {
  for (const detection of [
    { peak_g: '38.4' }, { delta_v_kmh: true }, { duration_ms: 1.5 },
    { axis_peak: 1 }, { rollover: 'false' }, { tilt_deg: {} },
    { gyro_max_dps: [] },
  ]) {
    rejects(topic, message({ detection }), 'INVALID_FIELD');
  }
});

test('device: accepts documented fields and partial diagnostic snapshots', () => {
  for (const device of [
    {},
    { degraded: false },
    { battery_v: 4.02, rssi_dbm: -73, operator: 'Test', uptime_s: 0,
      sd: true, degraded: false },
  ]) {
    assert.deepEqual(normalizeMqttEvent(topic, message({ device })).event.device, device);
  }
});

test('device: rejects incorrect types in known fields', () => {
  for (const device of [
    { battery_v: '4.02' }, { rssi_dbm: -73.5 }, { operator: false },
    { uptime_s: '1' }, { sd: 1 }, { degraded: 'false' },
  ]) {
    rejects(topic, message({ device }), 'INVALID_FIELD');
  }
});

test('rejects malformed optional fields and omits backend-owned fields', () => {
  rejects(topic, message({ severity: 'critical' }), 'INVALID_FIELD');
  rejects(topic, message({ position: [] }), 'INVALID_FIELD');
  rejects(topic, message({ position: { 'bad.key': 1 } }), 'INVALID_FIELD');
  rejects(topic, message({ detection: { metric: [{ value: 1 }] } }), 'INVALID_FIELD');
  rejects(topic, '{"id":"SDA-TEST","seq":1,"type":"crash","position":{"lat":1e999}}', 'INVALID_FIELD');
  rejects(topic, message({ queued: 'true' }), 'INVALID_FIELD');
  const result = normalizeMqttEvent(topic, message({
    vehicleId: 'injected', userId: 'injected', acknowledged: true,
    cancelledAt: 100, receivedAt: 100,
  }));
  assert.deepEqual(result.event, { id: 'SDA-TEST', seq: 1, type: 'crash' });
});
