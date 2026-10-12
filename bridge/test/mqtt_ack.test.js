import assert from 'node:assert/strict';
import net from 'node:net';
import test from 'node:test';
import mqtt from 'mqtt';
import { ingestMqttEvent } from '../event_writer.js';

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

// Minimal MQTT 3.1.1 broker for one QoS 1 delivery; no external listener.
test('A08: MQTT.js PUBACK precedes an asynchronous RTDB result', { timeout: 10000 }, async () => {
  const ack = deferred();
  const persistence = deferred();
  const failed = deferred();
  let settled = false;
  const topic = 'sda/SDA-TEST/event';
  const body = JSON.stringify({ id: 'SDA-TEST', seq: 1, type: 'crash' });
  const broker = net.createServer((socket) => {
    let buffer = Buffer.alloc(0);
    socket.on('data', (chunk) => {
      buffer = Buffer.concat([buffer, chunk]);
      while (buffer.length >= 2) {
        let length = 0;
        let multiplier = 1;
        let end = 1;
        let digit;
        do {
          if (end >= buffer.length) return;
          digit = buffer[end++];
          length += (digit & 0x7f) * multiplier;
          multiplier *= 128;
        } while (digit & 0x80);
        if (buffer.length < end + length) return;
        const packet = buffer.subarray(0, end + length);
        buffer = buffer.subarray(end + length);
        switch (packet[0] >> 4) {
          case 1: // CONNECT
            socket.write(Buffer.from([0x20, 0x02, 0x00, 0x00]));
            break;
          case 8: { // SUBSCRIBE
            const id = packet.subarray(end, end + 2);
            socket.write(Buffer.from([0x90, 0x03, id[0], id[1], 0x01]));
            const name = Buffer.from(topic);
            const payload = Buffer.from(body);
            const remaining = 2 + name.length + 2 + payload.length;
            socket.write(Buffer.concat([
              Buffer.from([0x32, remaining, name.length >> 8, name.length & 0xff]),
              name, Buffer.from([0x00, 0x07]), payload,
            ]));
            break;
          }
          case 4: // PUBACK
            if (packet[end] === 0x00 && packet[end + 1] === 0x07) ack.resolve();
            break;
          default:
            break;
        }
      }
    });
  });
  await new Promise((resolve) => broker.listen(0, '127.0.0.1', resolve));
  const client = mqtt.connect(`mqtt://127.0.0.1:${broker.address().port}`, {
    protocolVersion: 4, clean: false, clientId: 'local-ack-test', reconnectPeriod: 0,
  });
  try {
    client.on('connect', () => client.subscribe('sda/+/event', { qos: 1 }));
    client.on('message', async (receivedTopic, payload) => {
      try {
        await ingestMqttEvent(receivedTopic, payload, {
          db: { ref: () => ({ transaction: () => persistence.promise }) },
          resolveAssociation: async () => null,
          serverTimestamp: { '.sv': 'timestamp' },
        });
      } catch {
        settled = true;
        failed.resolve();
      }
    });
    await ack.promise;
    assert.equal(settled, false);
    persistence.reject(new Error('simulated RTDB failure'));
    await failed.promise;
    assert.equal(settled, true);
  } finally {
    client.end(true);
    await new Promise((resolve) => broker.close(resolve));
  }
});

test('MQTT.js reconnects and ingests queued, duplicate and later events', {
  timeout: 10000,
}, async () => {
  const first = deferred();
  const queued = deferred();
  const duplicate = deferred();
  const later = deferred();
  const closed = deferred();
  const sockets = new Set();
  const rows = new Map();
  const results = [];
  const topic = 'sda/SDA-TEST/event';
  const body = (seq) => Buffer.from(JSON.stringify({ id: 'SDA-TEST', seq, type: 'crash' }));
  let connections = 0;
  let reconnects = 0;
  let firstSocket;
  let secondSocket;
  let pending = [];
  const clientIds = [];
  const cleanFlags = [];
  const resumedSessions = [];

  function publish(socket, seq, packetId, retransmission = false) {
    const name = Buffer.from(topic);
    const payload = body(seq);
    const remaining = 2 + name.length + 2 + payload.length;
    assert.ok(remaining < 128);
    socket.write(Buffer.concat([
      Buffer.from([retransmission ? 0x3a : 0x32, remaining,
        name.length >> 8, name.length & 0xff]),
      name, Buffer.from([packetId >> 8, packetId & 0xff]), payload,
    ]));
  }

  const broker = net.createServer((socket) => {
    const connection = ++connections;
    sockets.add(socket);
    if (connection === 1) firstSocket = socket;
    if (connection === 2) secondSocket = socket;
    socket.on('close', () => sockets.delete(socket));
    let buffer = Buffer.alloc(0);
    socket.on('data', (chunk) => {
      buffer = Buffer.concat([buffer, chunk]);
      while (buffer.length >= 2) {
        let length = 0;
        let multiplier = 1;
        let end = 1;
        let digit;
        do {
          if (end >= buffer.length) return;
          digit = buffer[end++];
          length += (digit & 0x7f) * multiplier;
          multiplier *= 128;
        } while (digit & 0x80);
        if (buffer.length < end + length) return;
        const packet = buffer.subarray(0, end + length);
        buffer = buffer.subarray(end + length);
        switch (packet[0] >> 4) {
          case 1: { // CONNECT
            cleanFlags.push(Boolean(packet[end + 7] & 0x02));
            const idLength = packet.readUInt16BE(end + 10);
            clientIds.push(packet.subarray(end + 12, end + 12 + idLength).toString());
            socket.write(Buffer.from([0x20, 0x02, connection === 1 ? 0 : 1, 0]));
            if (connection > 1) {
              // A persistent broker session can send queued data immediately.
              for (const seq of pending) publish(socket, seq, 8);
              pending = [];
              publish(socket, 1, 9, true);
            }
            break;
          }
          case 8: { // SUBSCRIBE
            socket.write(Buffer.from([0x90, 0x03, packet[end], packet[end + 1], 0x01]));
            if (connection === 1) {
              publish(socket, 1, 7);
            }
            break;
          }
          default:
            break;
        }
      }
    });
  });
  await new Promise((resolve) => broker.listen(0, '127.0.0.1', resolve));
  const client = mqtt.connect(`mqtt://127.0.0.1:${broker.address().port}`, {
    protocolVersion: 4, clean: false, clientId: 'local-reconnect-test',
    reconnectPeriod: 50,
  });
  const db = { ref: (path) => ({
    transaction: async (update) => {
      const next = update(rows.get(path) ?? null);
      if (next === undefined) {
        return { committed: false, snapshot: { val: () => rows.get(path) } };
      }
      rows.set(path, next);
      return { committed: true, snapshot: { val: () => next } };
    },
    get: async () => ({ val: () => rows.get(path) }),
  }) };
  try {
    client.on('connect', (connack) => {
      resumedSessions.push(connack.sessionPresent);
      client.subscribe('sda/+/event', { qos: 1 });
    });
    client.on('reconnect', () => { reconnects++; });
    client.on('close', () => closed.resolve());
    client.on('message', async (receivedTopic, payload) => {
      try {
        const result = await ingestMqttEvent(receivedTopic, payload, {
          db, resolveAssociation: async () => null, serverTimestamp: 1000,
        });
        results.push(result);
        if (result.dedupKey === 'SDA-TEST_1' && result.written) first.resolve();
        if (result.dedupKey === 'SDA-TEST_2') queued.resolve();
        if (result.dedupKey === 'SDA-TEST_1' && !result.written) duplicate.resolve();
        if (result.dedupKey === 'SDA-TEST_3') later.resolve();
      } catch (error) {
        first.reject(error);
        queued.reject(error);
        duplicate.reject(error);
        later.reject(error);
      }
    });
    await first.promise;
    firstSocket.destroy();
    await closed.promise;
    pending.push(2); // Local broker retains this QoS 1 event while disconnected.
    await Promise.all([queued.promise, duplicate.promise]);
    publish(secondSocket, 3, 10); // New event after reconnection.
    await later.promise;
    assert.ok(reconnects >= 1);
    assert.equal(connections, 2);
    assert.deepEqual(cleanFlags, [false, false]);
    assert.deepEqual(clientIds, ['local-reconnect-test', 'local-reconnect-test']);
    assert.deepEqual(resumedSessions, [false, true]);
    assert.deepEqual(results.map(({ dedupKey, written }) => [dedupKey, written]), [
      ['SDA-TEST_1', true], ['SDA-TEST_2', true], ['SDA-TEST_1', false],
      ['SDA-TEST_3', true],
    ]);
    assert.deepEqual([...rows.keys()].sort(), [
      'events/SDA-TEST_1', 'events/SDA-TEST_2', 'events/SDA-TEST_3',
    ]);
  } finally {
    client.options.reconnectPeriod = 0;
    client.end(true);
    for (const socket of sockets) socket.destroy();
    await new Promise((resolve) => broker.close(resolve));
  }
});
