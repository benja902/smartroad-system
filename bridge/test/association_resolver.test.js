import assert from 'node:assert/strict';
import test from 'node:test';
import { AssociationLookupError, resolveAssociation } from '../association_resolver.js';

function database(read) {
  return {
    ref: (path) => {
      assert.equal(path, 'vehicles');
      return {
        orderByChild: (field) => {
          assert.equal(field, 'deviceId');
          return {
            equalTo: (id) => {
              assert.equal(id, 'SDA-TEST');
              return {
                limitToFirst: (limit) => {
                  assert.equal(limit, 2);
                  return { get: read };
                },
              };
            },
          };
        },
      };
    },
  };
}

test('A06: genuine absence returns null without an invented association', async () => {
  const result = await resolveAssociation(database(async () => ({ exists: () => false })), 'SDA-TEST');
  assert.equal(result, null);
});

test('A07: temporary failure and inconsistent record propagate as errors', async () => {
  await assert.rejects(resolveAssociation(database(async () => {
    throw new Error('temporary read failure');
  }), 'SDA-TEST'), (error) => error instanceof AssociationLookupError &&
    error.code === 'LOOKUP_FAILED');
  await assert.rejects(resolveAssociation(database(async () => ({
    exists: () => true,
    val: () => ({ 'vehicle-test': { deviceId: 'OTHER', ownerId: 'owner-test' } }),
  })), 'SDA-TEST'), (error) => error instanceof AssociationLookupError &&
    error.code === 'INCONSISTENT_RECORD');
});

test('administrative association comes only from matching vehicle record', async () => {
  const result = await resolveAssociation(database(async () => ({
    exists: () => true,
    val: () => ({ 'vehicle-test': { deviceId: 'SDA-TEST', ownerId: 'owner-test' } }),
  })), 'SDA-TEST');
  assert.deepEqual(result, { vehicleId: 'vehicle-test', userId: 'owner-test' });
});

test('duplicate deviceId associations are rejected instead of choosing the first owner', async () => {
  await assert.rejects(resolveAssociation(database(async () => ({
    exists: () => true,
    val: () => ({
      'vehicle-test-a': { deviceId: 'SDA-TEST', ownerId: 'owner-a' },
      'vehicle-test-b': { deviceId: 'SDA-TEST', ownerId: 'owner-b' },
    }),
  })), 'SDA-TEST'), (error) => error instanceof AssociationLookupError &&
    error.code === 'AMBIGUOUS_ASSOCIATION');
});
