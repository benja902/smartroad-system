import 'package:firebase_database/firebase_database.dart';

/// One-time provisioning helper: since there's no real ESP32 writing to
/// Firebase yet, a freshly created Firebase Auth user has no
/// users/vehicles/devices data. This seeds a demo profile + vehicle +
/// device (matching the shape docs/device_contract.md expects the real
/// firmware to eventually write) the first time a user signs in, so the
/// app is genuinely testable end-to-end against the real backend.
///
/// Remove this once real device provisioning (or an admin/onboarding flow)
/// exists — it's a stand-in for that, not a permanent feature.
class FirebaseBootstrapService {
  final FirebaseDatabase _database;

  FirebaseBootstrapService({FirebaseDatabase? database}) : _database = database ?? FirebaseDatabase.instance;

  Future<void> ensureDemoDataSeeded(String uid, {required String email, String? displayName}) async {
    final userRef = _database.ref('users/$uid');
    final existing = await userRef.get();
    if (existing.exists) return;

    final deviceId = 'device-$uid';
    final vehicleId = 'vehicle-$uid';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await Future.wait([
      userRef.set({
        'name': displayName ?? email.split('@').first,
        'email': email,
        'phone': null,
        'vehicleIds': {vehicleId: true},
      }),
      _database.ref('vehicles/$vehicleId').set({
        'ownerId': uid,
        'deviceId': deviceId,
        'brand': 'Toyota',
        'model': 'Hilux',
        'plate': 'ABC-123',
      }),
      _database.ref('devices/$deviceId/status').set({
        'online': true,
        'monitoring': true,
        'lastSeen': nowMs,
      }),
      _database.ref('devices/$deviceId/hardware').set({
        'adxl375Connected': true,
        'lsm6ds3Connected': true,
        'sim7000Connected': true,
      }),
      _database.ref('devices/$deviceId/network').set({
        'cellularConnected': true,
        'networkType': 'cellular4g',
        'signalStrength': 4,
      }),
      _database.ref('devices/$deviceId/gnss').set({
        'available': true,
        'fix': true,
      }),
      _database.ref('devices/$deviceId/location').set({
        'latitude': -12.046374,
        'longitude': -77.042793,
        'displayName': 'Av. Javier Prado Este, San Isidro, Lima',
        'updatedAt': nowMs,
      }),
    ]);
  }
}
