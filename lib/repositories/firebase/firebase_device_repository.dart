import 'package:firebase_database/firebase_database.dart';

import '../../models/device_status.dart';
import '../../models/location_model.dart';
import '../device_repository.dart';

/// Firebase-backed DeviceRepository. Reads the whole devices/{deviceId}
/// node (status/hardware/network/gnss/location subnodes, written by the
/// ESP32 firmware per docs/device_contract.md) and assembles it into the
/// flat DeviceStatus model the app uses. Firebase's onValue already fires
/// once immediately with the current value on subscribe, so this satisfies
/// the same replay-then-live contract as the mock.
class FirebaseDeviceRepository implements DeviceRepository {
  final DatabaseReference _devicesRef;

  FirebaseDeviceRepository({FirebaseDatabase? database})
      : _devicesRef = (database ?? FirebaseDatabase.instance).ref('devices');

  @override
  Stream<DeviceStatus> watchStatus(String deviceId) {
    return _devicesRef.child(deviceId).onValue.map((event) => _fromSnapshot(deviceId, event.snapshot));
  }

  @override
  Future<DeviceStatus> getStatus(String deviceId) async {
    final snapshot = await _devicesRef.child(deviceId).get();
    return _fromSnapshot(deviceId, snapshot);
  }

  DeviceStatus _fromSnapshot(String deviceId, DataSnapshot snapshot) {
    final data = snapshot.value == null ? const {} : Map<String, dynamic>.from(snapshot.value as Map);

    final status = _asMap(data['status']);
    final hardware = _asMap(data['hardware']);
    final network = _asMap(data['network']);
    final gnss = _asMap(data['gnss']);
    final location = _asMap(data['location']);

    return DeviceStatus(
      deviceId: deviceId,
      online: status['online'] as bool? ?? false,
      monitoring: status['monitoring'] as bool? ?? false,
      adxl375Connected: hardware['adxl375Connected'] as bool? ?? false,
      lsm6ds3Connected: hardware['lsm6ds3Connected'] as bool? ?? false,
      sim7000Connected: hardware['sim7000Connected'] as bool? ?? false,
      cellularConnected: network['cellularConnected'] as bool? ?? false,
      networkType: _parseNetworkType(network['networkType'] as String?),
      signalStrength: (network['signalStrength'] as num?)?.toInt() ?? 0,
      gnssAvailable: gnss['available'] as bool? ?? false,
      gnssFix: gnss['fix'] as bool? ?? false,
      lastSeen: _parseTimestamp(status['lastSeen']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      location: location.isEmpty
          ? null
          : LocationModel(
              latitude: (location['latitude'] as num).toDouble(),
              longitude: (location['longitude'] as num).toDouble(),
              displayName: location['displayName'] as String?,
              updatedAt: _parseTimestamp(location['updatedAt']) ?? DateTime.now(),
            ),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value == null) return const {};
    return Map<String, dynamic>.from(value as Map);
  }

  NetworkType _parseNetworkType(String? value) {
    return NetworkType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NetworkType.none,
    );
  }

  DateTime? _parseTimestamp(Object? value) {
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch((value as num).toInt());
  }
}
