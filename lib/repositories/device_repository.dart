import '../models/device_status.dart';

abstract class DeviceRepository {
  /// Emits the current status immediately on subscribe, then again on every
  /// change (replay-then-live), mirroring Firebase Realtime Database's
  /// onValue behavior.
  Stream<DeviceStatus> watchStatus(String deviceId);

  Future<DeviceStatus> getStatus(String deviceId);
}
