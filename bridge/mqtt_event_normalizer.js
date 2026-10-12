// Pure validation of sda/{deviceId}/event messages. It does not resolve
// associations, acknowledge MQTT messages, or write to RTDB.

const incidentTypes = new Set(['crash', 'rollover', 'sos']);
const technicalTypes = new Set(['test', 'power_loss', 'low_battery', 'booted']);
const severities = new Set(['none', 'leve', 'moderado', 'grave']);
const eventFields = [
  'id', 'seq', 'type', 'severity', 'ts', 'time_src', 'uptime_s',
  'vehicle_label', 'contact_phone', 'detection', 'position', 'device',
  'queued', 'cancels_seq', 'reason', 'elapsed_s',
];
const invalidKeyCharacters = /[.#+$\/\[\]\u0000-\u001f\u007f]/u;
const decoder = new TextDecoder('utf-8', { fatal: true });
// Bridge processing limit, not a claimed firmware or broker payload limit.
export const MAX_MQTT_EVENT_BYTES = 64 * 1024;

export class MqttEventValidationError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'MqttEventValidationError';
    this.code = code;
  }
}

function fail(code, message) {
  throw new MqttEventValidationError(code, message);
}

function isRecord(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isUsableSeq(value) {
  return Number.isSafeInteger(value) && value >= 0;
}

export function isUsableDeviceId(value) {
  return typeof value === 'string' && value.length > 0 &&
    !invalidKeyCharacters.test(value);
}

export function isUsableEventKey(deviceId, seq) {
  return isUsableDeviceId(deviceId) && isUsableSeq(seq) &&
    Buffer.byteLength(`${deviceId}_${seq}`, 'utf8') <= 768;
}

const finiteNumber = (value) => typeof value === 'number' && Number.isFinite(value);
const latitude = (value) => finiteNumber(value) && value >= -90 && value <= 90;
const longitude = (value) => finiteNumber(value) && value >= -180 && value <= 180;
const safeInteger = (value) => Number.isSafeInteger(value);
const textValue = (value) => typeof value === 'string';
const booleanValue = (value) => typeof value === 'boolean';
const snapshotFields = {
  position: {
    fix: booleanValue, lat: latitude, lon: longitude,
    alt_m: finiteNumber, speed_kmh: finiteNumber, heading: finiteNumber,
    hdop: finiteNumber, sats: safeInteger, fix_age_s: safeInteger,
  },
  detection: {
    peak_g: finiteNumber, delta_v_kmh: finiteNumber, duration_ms: safeInteger,
    axis_peak: textValue, rollover: booleanValue, tilt_deg: finiteNumber,
    gyro_max_dps: finiteNumber,
  },
  device: {
    battery_v: finiteNumber, rssi_dbm: safeInteger, operator: textValue,
    uptime_s: safeInteger, sd: booleanValue, degraded: booleanValue,
  },
};

function isSafeSnapshot(value) {
  const pending = [{ value, depth: 0 }];
  while (pending.length > 0) {
    const current = pending.pop();
    if (current.depth > 25) return false;
    for (const [key, item] of Object.entries(current.value)) {
      if (!key || invalidKeyCharacters.test(key) ||
          Buffer.byteLength(key, 'utf8') > 768 ||
          ['__proto__', 'constructor', 'prototype'].includes(key)) return false;
      if (item !== null && typeof item === 'object') {
        if (Array.isArray(item)) return false;
        pending.push({ value: item, depth: current.depth + 1 });
      } else if (typeof item === 'number' && !Number.isFinite(item)) {
        return false;
      }
    }
  }
  return true;
}

function isValidSnapshot(field, value) {
  if (!isRecord(value) || !isSafeSnapshot(value)) return false;
  if (field === 'position' && (!latitude(value.lat) || !longitude(value.lon))) {
    return false;
  }
  for (const [key, predicate] of Object.entries(snapshotFields[field])) {
    if (value[key] !== undefined && value[key] !== null && !predicate(value[key])) {
      return false;
    }
  }
  return true;
}

function checkOptional(event, field, predicate) {
  if (event[field] !== undefined && event[field] !== null && !predicate(event[field])) {
    fail('INVALID_FIELD', `Invalid ${field}`);
  }
}

function parsePayload(payload) {
  let json;
  try {
    if ((Buffer.isBuffer(payload) && payload.length > MAX_MQTT_EVENT_BYTES) ||
        (typeof payload === 'string' &&
          Buffer.byteLength(payload, 'utf8') > MAX_MQTT_EVENT_BYTES)) {
      fail('PAYLOAD_TOO_LARGE', 'Event payload exceeds bridge processing limit');
    }
    json = Buffer.isBuffer(payload) ? decoder.decode(payload) : payload;
    if (typeof json !== 'string') fail('INVALID_JSON', 'Event payload must be JSON');
    json = JSON.parse(json);
  } catch (error) {
    if (error instanceof MqttEventValidationError) throw error;
    fail('INVALID_JSON', 'Event payload is not valid JSON');
  }
  if (!isRecord(json)) fail('INVALID_PAYLOAD', 'Event payload must be an object');
  return json;
}

/**
 * Returns firmware fields without inventing timestamps, severity, or association.
 * `kind` is diagnostic for unknown types; persistence and Flutter must not
 * promote that kind to an emergency. 2.1b may discard malformed optional
 * blocks while keeping a valid incident; the default retains 2.1a's rejection.
 */
export function normalizeMqttEvent(topic, payload, { prefix = 'sda', optionalBlockPolicy = 'reject' } = {}) {
  if (typeof topic !== 'string' || typeof prefix !== 'string' || !prefix ||
      topic.split('/').length !== 3) {
    fail('INVALID_TOPIC', 'Expected an SDA event topic');
  }
  const [topicPrefix, deviceId, leaf] = topic.split('/');
  if (topicPrefix !== prefix || leaf !== 'event' ||
      !isUsableDeviceId(deviceId)) {
    fail('INVALID_TOPIC', 'Expected an SDA event topic');
  }

  const raw = parsePayload(payload);
  if (typeof raw.id !== 'string' || raw.id !== deviceId) {
    fail('INVALID_ID', 'Payload id does not match topic deviceId');
  }
  if (!isUsableEventKey(deviceId, raw.seq)) {
    fail('INVALID_SEQ', 'Event seq cannot form a valid RTDB key');
  }
  if (typeof raw.type !== 'string' || raw.type.trim() === '') {
    fail('INVALID_TYPE', 'Event type is required');
  }

  if (raw.type === 'cancel') {
    if (!isUsableEventKey(deviceId, raw.cancels_seq) ||
        raw.cancels_seq === raw.seq) {
      fail('INVALID_CANCEL_REFERENCE', 'Cancel must reference another valid seq');
    }
  } else if (raw.cancels_seq !== undefined && raw.cancels_seq !== null) {
    fail('INVALID_CANCEL_REFERENCE', 'Only cancel can reference another seq');
  }

  checkOptional(raw, 'severity', (value) => typeof value === 'string' && severities.has(value));
  checkOptional(raw, 'ts', (value) =>
    typeof value === 'string' || (typeof value === 'number' && Number.isFinite(value)));
  checkOptional(raw, 'time_src', (value) => typeof value === 'string');
  checkOptional(raw, 'uptime_s', isUsableSeq);
  checkOptional(raw, 'queued', (value) => typeof value === 'boolean');
  const diagnostics = [];
  const rejectedBlocks = new Set();
  for (const field of ['detection', 'position', 'device']) {
    if (raw[field] !== undefined && raw[field] !== null && !isValidSnapshot(field, raw[field])) {
      if (optionalBlockPolicy !== 'drop') fail('INVALID_FIELD', `Invalid ${field}`);
      rejectedBlocks.add(field);
      diagnostics.push(`INVALID_OPTIONAL_${field.toUpperCase()}`);
    }
  }
  checkOptional(raw, 'vehicle_label', (value) => typeof value === 'string');
  checkOptional(raw, 'contact_phone', (value) => typeof value === 'string');
  checkOptional(raw, 'reason', (value) => typeof value === 'string');
  checkOptional(raw, 'elapsed_s', isUsableSeq);

  const event = {};
  for (const field of eventFields) {
    if (!rejectedBlocks.has(field) && raw[field] !== undefined && raw[field] !== null) {
      event[field] = raw[field];
    }
  }

  const kind = incidentTypes.has(raw.type) ? 'incident'
    : raw.type === 'cancel' ? 'cancellation'
      : technicalTypes.has(raw.type) ? 'technical' : 'diagnostic';
  return { deviceId, event, kind, ...(diagnostics.length ? { diagnostics } : {}) };
}
