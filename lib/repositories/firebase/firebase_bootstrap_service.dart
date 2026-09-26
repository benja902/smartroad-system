import 'package:firebase_database/firebase_database.dart';

/// One-time provisioning helper: since there's no real backend bridge
/// writing to Firebase yet, a freshly created Firebase Auth user has no
/// users/vehicles/devices data. This seeds a demo profile + vehicle +
/// device status (matching docs/device_contract.md's shape) the first
/// time a user signs in, so the app is genuinely testable end-to-end
/// against the real backend.
///
/// Remove this once the real MQTT→Firebase bridge exists — it's a
/// stand-in for that, not a permanent feature.
class FirebaseBootstrapService {
  final FirebaseDatabase _database;

  FirebaseBootstrapService({FirebaseDatabase? database}) : _database = database ?? FirebaseDatabase.instance;

  Future<void> ensureDemoDataSeeded(String uid, {required String email, String? displayName}) async {
    final userRef = _database.ref('users/$uid');
    final existing = await userRef.get();
    if (existing.exists) return;

    final deviceId = 'SDA-DEMO${uid.substring(0, 6).toUpperCase()}';
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
      _database.ref('devices/$deviceId').set({
        'state': 'idle',
        'fw': '1.0.0',
        'sensors': {
          'adxl375': {'ok': true, 'addr': '0x53', 'peak_g_60s': 1.4},
          'lsm6ds3tr': {'ok': true, 'addr': '0x6A', 'tilt_deg': 3.1, 'gyro_max_dps': 12.0},
          'pcf8574': {'ok': true, 'addr': '0x20'},
        },
        'inputs': {'sos': false, 'cancel': false},
        'outputs': {'led_red': false, 'led_green': true, 'buzzer': false},
        'sd': {'present': true, 'total_mb': 15200, 'free_mb': 14980, 'queued_events': 0},
        'modem': {'registered': true, 'tech': 'LTE', 'operator': 'Claro PE', 'rssi_dbm': -73},
        'gnss': {
          'fix': true,
          'lat': -12.046374,
          'lon': -77.042793,
          'alt_m': 154.0,
          'speed_kmh': 0.0,
          'heading': 218.0,
          'hdop': 1.1,
          'sats': 9,
          'fix_age_s': 2,
        },
        'power': {'battery_v': 4.02, 'charging': true, 'vin_ok': true},
        'system': {'uptime_s': 48213, 'heap_free': 148320, 'reset_reason': 'POWERON'},
        'online': true,
        'lastSeen': nowMs,
      }),
    ]);
  }
}
