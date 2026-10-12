// A missing administrative record differs from a failed or inconsistent read.
export class AssociationLookupError extends Error {
  constructor(code, cause) {
    super(code, { cause });
    this.name = 'AssociationLookupError';
    this.code = code;
  }
}

export async function resolveAssociation(db, deviceId) {
  let snapshot;
  try {
    snapshot = await db.ref('vehicles')
      .orderByChild('deviceId')
      .equalTo(deviceId)
      .limitToFirst(2)
      .get();
  } catch (error) {
    throw new AssociationLookupError('LOOKUP_FAILED', error);
  }

  if (!snapshot.exists()) return null;
  const matches = Object.entries(snapshot.val());
  if (matches.length !== 1) {
    throw new AssociationLookupError('AMBIGUOUS_ASSOCIATION');
  }
  const [vehicleId, vehicle] = matches[0];
  if (!vehicle || vehicle.deviceId !== deviceId ||
      typeof vehicle.ownerId !== 'string' || !vehicle.ownerId || !vehicleId) {
    throw new AssociationLookupError('INCONSISTENT_RECORD');
  }
  return { vehicleId, userId: vehicle.ownerId };
}
