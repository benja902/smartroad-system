import assert from 'node:assert/strict';
import test from 'node:test';
import { createContactRecovery } from '../contact_operations.js';

function harness(reconcile, enabled = true) {
  let timer, scheduled = 0;
  const recover = createContactRecovery({ reconcile, enabled, scheduleRecovery: () => {
    if (!timer) { scheduled++; timer = () => recover(); }
  } });
  return { recover, scheduled: () => scheduled, pending: () => !!timer,
    async tick() { assert.ok(timer); const callback = timer; timer = undefined; await callback(); } };
}

test('recovery requests during an active pass coalesce into one delayed pass', async () => {
  let release; const held = new Promise(resolve => { release = resolve; });
  let passes = 0, active = 0, maximum = 0;
  const h = harness(async () => {
    active++; maximum = Math.max(maximum, active);
    try { if (++passes === 1) await held; } finally { active--; }
  });
  const first = h.recover();
  await Promise.all(Array.from({ length: 12 }, () => h.recover()));
  assert.equal(passes, 1); assert.equal(h.scheduled(), 0);
  release(); await first;
  assert.equal(passes, 1, 'no immediate retry loop');
  assert.equal(h.scheduled(), 1); await h.tick();
  assert.equal(passes, 2); assert.equal(maximum, 1); assert.equal(h.pending(), false);
});

test('transient failures retain work and wait for the shared timer before retrying', async () => {
  let passes = 0;
  const h = harness(async () => { if (++passes < 3) throw Error('transient failure'); });
  await h.recover(); assert.equal(passes, 1); assert.equal(h.scheduled(), 1);
  await h.tick(); assert.equal(passes, 2); assert.equal(h.scheduled(), 2);
  await h.tick(); assert.equal(passes, 3); assert.equal(h.pending(), false);
});

test('failure plus concurrent requests needs only one delayed retry', async () => {
  let fail; const blocked = new Promise((_, reject) => { fail = reject; });
  let passes = 0;
  const h = harness(async () => { if (++passes === 1) await blocked; });
  const first = h.recover(); await h.recover(); await h.recover();
  fail(Error('temporary outage')); await first;
  assert.equal(h.scheduled(), 1); await h.tick();
  assert.equal(passes, 2); assert.equal(h.pending(), false);
});

test('disabled recovery does not read or schedule work', async () => {
  let passes = 0; const h = harness(async () => { passes++; }, false);
  await h.recover(); await h.recover();
  assert.equal(passes, 0); assert.equal(h.scheduled(), 0);
});
