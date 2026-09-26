import 'package:firebase_database/firebase_database.dart';

import '../../models/device_status.dart';
import '../device_repository.dart';

/// Firebase-backed DeviceRepository. Reads devices/{deviceId}, written by
/// the backend bridge with the fields of the last `status` message plus
/// `online`/`lastSeen` projected from the `availability` channel (see
/// docs/device_contract.md). Firebase's onValue already fires once
/// immediately with the current value on subscribe, satisfying the same
/// replay-then-live contract as the mock.
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
    final data = snapshot.value == null ? const <String, dynamic>{} : Map<String, dynamic>.from(snapshot.value as Map);
    return DeviceStatus.fromJson(deviceId, data);
  }
}
