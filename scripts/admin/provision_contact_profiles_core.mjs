import { isDeepStrictEqual } from 'node:util';
import { ProvisionError, selectExisting } from './provision_mvp_core.mjs';

const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const validKey = value => typeof value === 'string' && value.length > 0 && value === value.trim()
  && !/[.#$\[\]/\u0000-\u001f\u007f]/.test(value)
  && !['__proto__', 'constructor', 'prototype'].includes(value);

function requireValue(ok, code) {
  if (!ok) throw new ProvisionError(code);
}

export function buildContactProfilePlan(snapshot, selection, requestedContacts, verifiedUsers) {
  requireValue(Array.isArray(requestedContacts) && requestedContacts.length >= 1
    && requestedContacts.length <= 3, 'CONTACT_LIMIT_EXCEEDED');
  const { ownerUid, vehicleId, deviceId } = selection;
  const users = snapshot.users ?? {}, vehicles = snapshot.vehicles ?? {};
  const registry = snapshot.deviceRegistry ?? {}, relations = snapshot.vehicleContacts ?? {};
  requireValue([users, vehicles, snapshot.devices ?? {}, registry, relations].every(object), 'INVALID_DATABASE_SHAPE');
  requireValue(Object.keys(vehicles).length === 1 && vehicles[vehicleId]?.ownerId === ownerUid
    && vehicles[vehicleId]?.deviceId === deviceId && object(snapshot.devices?.[deviceId])
    && registry[deviceId]?.vehicleId === vehicleId && registry[deviceId]?.active === true,
  'VEHICLE_ASSOCIATION_CONFLICT');
  requireValue(object(users[ownerUid]) && users[ownerUid].vehicleIds?.[vehicleId] === true
    && verifiedUsers[ownerUid]?.exists === true && verifiedUsers[ownerUid]?.disabled === false,
  'OWNER_NOT_CONFIRMED');
  const currentRelations = relations[vehicleId] ?? {};
  requireValue(object(currentRelations), 'INVALID_CONTACT_RELATIONS');
  const occupied = new Set(Object.entries(currentRelations)
    .filter(([, relation]) => ['pending', 'active'].includes(relation?.status))
    .map(([uid]) => uid));
  const patch = {}, changes = [], seen = new Set();
  for (const [index, contact] of requestedContacts.entries()) {
    requireValue(object(contact) && validKey(contact.uid) && contact.uid !== ownerUid
      && !seen.has(contact.uid) && contact.confirmed === true
      && typeof contact.name === 'string' && contact.name.trim() === contact.name
      && contact.name.length > 0 && contact.name.length <= 120
      && Object.keys(contact).every(field => ['uid', 'name', 'confirmed'].includes(field)),
    'CONFIRMED_CONTACT_REQUIRED');
    seen.add(contact.uid);
    const authUser = verifiedUsers[contact.uid];
    requireValue(authUser?.exists === true && typeof authUser.email === 'string'
      && authUser.email.includes('@'), 'CONTACT_AUTH_NOT_CONFIRMED');
    requireValue(authUser.disabled === true, 'CONTACT_ACCOUNT_MUST_BE_DISABLED');
    const relation = currentRelations[contact.uid];
    requireValue(relation === undefined || relation?.status === 'pending',
      'CONTACT_RELATION_REQUIRES_REVIEW');
    occupied.add(contact.uid);
    const profile = users[contact.uid];
    requireValue(profile === undefined || object(profile), 'CONTACT_PROFILE_INVALID');
    requireValue(profile?.vehicleIds?.[vehicleId] !== true, 'CONTACT_ACCESS_PREEXISTS');
    const expected = { name: contact.name, email: authUser.email };
    for (const [field, value] of Object.entries(expected)) {
      const before = profile?.[field];
      requireValue(before === undefined || before === value, 'CONTACT_PROFILE_CONFLICT');
      if (before === undefined) {
        patch[`users/${contact.uid}/${field}`] = value;
        changes.push({ path: `users/{confirmedContact${index + 1}}/${field}`,
          previous: 'absent', value: '{confirmedValueHidden}' });
      }
    }
  }
  requireValue(occupied.size <= 3, 'CONTACT_LIMIT_EXCEEDED');
  return { patch, changes, confirmedContacts: requestedContacts.length };
}

export async function runContactProfileProvision(adapter, { contacts, confirmedSuffix, apply = false }) {
  requireValue(typeof apply === 'boolean', 'INVALID_MODE');
  let selection;
  async function prepare() {
    const snapshot = await adapter.readSnapshot();
    if (selection === undefined) selection = selectExisting(snapshot, confirmedSuffix);
    const ids = [selection.ownerUid, ...(contacts ?? []).map(contact => contact?.uid)];
    requireValue(ids.every(validKey), 'INVALID_IDENTIFIER');
    const verifiedUsers = await adapter.verifyUsers([...new Set(ids)]);
    return buildContactProfilePlan(snapshot, selection, contacts, verifiedUsers);
  }
  const plan = await prepare();
  let writesPerformed = 0;
  if (apply && plan.changes.length > 0) {
    const fresh = await prepare();
    requireValue(isDeepStrictEqual(plan.patch, fresh.patch), 'STATE_CHANGED_REVIEW_REQUIRED');
    await adapter.updateFields(plan.patch);
    writesPerformed = 1;
  }
  return {
    mode: apply ? 'apply' : 'dry-run', writesPerformed,
    proposedChanges: plan.changes, confirmedContacts: plan.confirmedContacts,
    preservedNodes: ['existing user fields', 'vehicles', 'devices', 'deviceRegistry',
      'vehicleContacts', 'events', 'userIncidentState'],
  };
}
