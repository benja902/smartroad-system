import { isDeepStrictEqual } from 'node:util';

// Sin SDK, credenciales ni efectos al importar. Solo un vehículo y un SDA.
export class ProvisionError extends Error {
  constructor(code) { super(code); this.code = code; }
}

function requireValue(ok, code) {
  if (!ok) throw new ProvisionError(code);
}

const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const key = value => typeof value === 'string' && value.length > 0 && value === value.trim()
  && !/[.#$\[\]/\u0000-\u001f\u007f]/.test(value)
  && !['__proto__', 'constructor', 'prototype'].includes(value);

export function selectExisting(snapshot, confirmedSuffix) {
  const entries = Object.entries(snapshot.vehicles ?? {});
  requireValue(entries.length === 1, 'EXACTLY_ONE_VEHICLE_REQUIRED');
  const [[vehicleId, vehicle]] = entries;
  requireValue(object(vehicle) && key(vehicle.deviceId), 'INVALID_VEHICLE');
  requireValue(typeof confirmedSuffix === 'string' && confirmedSuffix.length >= 4
    && confirmedSuffix.length < vehicle.deviceId.length
    && vehicle.deviceId.endsWith(confirmedSuffix), 'CONFIRMED_DEVICE_SUFFIX_MISMATCH');
  return { ownerUid: vehicle.ownerId, vehicleId, deviceId: vehicle.deviceId, deviceConfirmed: true };
}

export function buildPlan(snapshot, request, verifiedUsers) {
  requireValue(object(request), 'INVALID_REQUEST');
  const { ownerUid, vehicleId, deviceId } = request;
  requireValue([ownerUid, vehicleId, deviceId].every(key), 'INVALID_IDENTIFIER');
  requireValue(request.deviceConfirmed === true, 'DEVICE_CONFIRMATION_REQUIRED');
  const users = snapshot.users ?? {}, vehicles = snapshot.vehicles ?? {};
  const registry = snapshot.deviceRegistry ?? {}, contacts = snapshot.vehicleContacts ?? {};
  requireValue([users, vehicles, snapshot.devices ?? {}, registry, contacts].every(object), 'INVALID_DATABASE_SHAPE');
  requireValue(Object.keys(vehicles).length === 1, 'EXACTLY_ONE_VEHICLE_REQUIRED');
  const vehicle = vehicles[vehicleId];
  requireValue(object(vehicle), 'VEHICLE_NOT_FOUND');
  requireValue(vehicle.ownerId === ownerUid && vehicle.deviceId === deviceId, 'VEHICLE_ASSOCIATION_CONFLICT');
  requireValue(object(users[ownerUid]), 'OWNER_PROFILE_NOT_FOUND');
  requireValue(verifiedUsers[ownerUid]?.exists === true && verifiedUsers[ownerUid]?.disabled === false, 'OWNER_AUTH_NOT_CONFIRMED');
  requireValue(object(users[ownerUid].vehicleIds) && users[ownerUid].vehicleIds[vehicleId] === true, 'OWNER_VEHICLE_INDEX_CONFLICT');
  requireValue(object(snapshot.devices?.[deviceId]), 'DEVICE_NOT_FOUND');
  requireValue(['brand', 'model', 'plate'].every(field => typeof vehicle[field] === 'string'), 'VEHICLE_FIELDS_INVALID');

  const current = registry[deviceId];
  requireValue(current === undefined || object(current), 'INVALID_REGISTRY');
  requireValue(current?.vehicleId === undefined || current.vehicleId === vehicleId, 'REGISTRY_ASSOCIATION_CONFLICT');
  requireValue(current?.active === undefined || current.active === true, 'REGISTRY_ACTIVATION_REQUIRES_REVIEW');
  requireValue(!Object.entries(registry).some(([id, data]) => id !== deviceId
    && data?.vehicleId === vehicleId && data?.active === true), 'OTHER_ACTIVE_DEVICE_CONFLICT');

  const patch = {}, changes = [];
  function propose(path, before, after, displayedPath, displayedValue) {
    if (isDeepStrictEqual(before, after)) return;
    patch[path] = after;
    changes.push({ path: displayedPath, previous: before === undefined ? 'absent' : 'present', value: displayedValue });
  }
  const registryPath = `deviceRegistry/${deviceId}`;
  propose(`${registryPath}/vehicleId`, current?.vehicleId, vehicleId,
    'deviceRegistry/{confirmedDevice}/vehicleId', '{existingVehicle}');
  propose(`${registryPath}/active`, current?.active, true,
    'deviceRegistry/{confirmedDevice}/active', true);

  if (request.rockblockImei !== undefined) {
    requireValue(request.imeiConfirmed === true && typeof request.rockblockImei === 'string'
      && /^[0-9]{15}$/.test(request.rockblockImei), 'CONFIRMED_IMEI_REQUIRED');
    requireValue(current?.rockblockImei === undefined || current.rockblockImei === request.rockblockImei, 'IMEI_CHANGE_REQUIRES_REVIEW');
    requireValue(!Object.entries(registry).some(([id, data]) => id !== deviceId
      && data?.rockblockImei === request.rockblockImei), 'IMEI_ASSOCIATION_CONFLICT');
    propose(`${registryPath}/rockblockImei`, current?.rockblockImei, request.rockblockImei,
      'deviceRegistry/{confirmedDevice}/rockblockImei', '{confirmedImeiHidden}');
  }

  const requestedContacts = request.contacts ?? [];
  requireValue(Array.isArray(requestedContacts), 'INVALID_CONTACTS');
  const seen = new Set();
  for (const [index, contact] of requestedContacts.entries()) {
    requireValue(object(contact) && key(contact.uid) && contact.confirmed === true, 'CONFIRMED_CONTACT_REQUIRED');
    requireValue(contact.uid !== ownerUid && !seen.has(contact.uid), 'CONTACT_IDENTITY_CONFLICT');
    seen.add(contact.uid);
    requireValue(object(users[contact.uid]) && verifiedUsers[contact.uid]?.exists === true
      && verifiedUsers[contact.uid]?.disabled === false, 'CONTACT_PROFILE_OR_AUTH_NOT_CONFIRMED');
    requireValue(contacts[vehicleId] === undefined || object(contacts[vehicleId]), 'INVALID_CONTACT_RELATIONS');
    const relation = contacts[vehicleId]?.[contact.uid];
    requireValue(relation === undefined || (object(relation)
      && ['pending', 'active', 'revoked'].includes(relation.status)), 'CONTACT_RELATION_REQUIRES_REVIEW');
    // No activa, revoca ni reactiva autorizaciones existentes.
    if (relation === undefined) propose(`vehicleContacts/${vehicleId}/${contact.uid}/status`, undefined, 'pending',
      `vehicleContacts/{existingVehicle}/{confirmedContact${index + 1}}/status`, 'pending');
  }
  return { patch, changes, requestedContacts: requestedContacts.length, imeiSupplied: request.rockblockImei !== undefined };
}

export async function runProvision(adapter, { request, confirmedSuffix, apply = false } = {}) {
  requireValue(typeof apply === 'boolean', 'INVALID_MODE');
  let selection = request === undefined ? undefined : structuredClone(request);
  async function prepare() {
    const snapshot = await adapter.readSnapshot();
    // Fijar la asociación seleccionada: nunca adoptar otro propietario
    // silenciosamente durante la revalidación del modo apply.
    if (selection === undefined) selection = selectExisting(snapshot, confirmedSuffix);
    const selected = selection;
    requireValue(object(selected) && Array.isArray(selected.contacts ?? []), 'INVALID_REQUEST');
    const ids = [selected.ownerUid, ...(selected.contacts ?? []).map(c => c?.uid)];
    requireValue(ids.every(key), 'INVALID_IDENTIFIER');
    const verifiedUsers = await adapter.verifyUsers([...new Set(ids)]);
    return buildPlan(snapshot, selected, verifiedUsers);
  }
  const plan = await prepare();
  let writesPerformed = 0;
  if (apply && plan.changes.length > 0) {
    // Revalidar justo antes de escribir; no aplicar un plan que haya cambiado.
    const fresh = await prepare();
    requireValue(isDeepStrictEqual(plan.patch, fresh.patch), 'STATE_CHANGED_REVIEW_REQUIRED');
    await adapter.updateFields(plan.patch);
    writesPerformed = 1;
  }
  // Nunca devolver el patch con identificadores reales a los logs del CLI.
  return {
    mode: apply ? 'apply' : 'dry-run', writesPerformed,
    proposedChanges: plan.changes,
    optionalInputs: { confirmedImeiSupplied: plan.imeiSupplied, confirmedContacts: plan.requestedContacts },
    preservedNodes: ['users', 'vehicles', 'devices (all records)', 'events', 'userIncidentState'],
  };
}
