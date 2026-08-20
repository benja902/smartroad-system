import 'dart:async';

import '../../models/device_status.dart';
import '../device_repository.dart';
import 'mock_data_seed.dart';

/// Mock DeviceRepository. Also exposes dev-simulator-only mutators
/// (setDeviceOffline, setCellularOffline, ...) that live on this concrete
/// class, not on the DeviceRepository interface, so production code never
/// depends on them existing — the /dev panel casts to this type explicitly.
class MockDeviceRepository implements DeviceRepository {
  final _controller = StreamController<DeviceStatus>.broadcast();
  DeviceStatus _current = MockDataSeed.initialDeviceStatus;

  @override
  Stream<DeviceStatus> watchStatus(String deviceId) async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<DeviceStatus> getStatus(String deviceId) async => _current;

  void setSystemOperational(bool operational) {
    _emit(_current.copyWith(online: operational, monitoring: operational));
  }

  void setDeviceOffline(bool offline) {
    _emit(_current.copyWith(online: !offline));
  }

  void setCellularOffline(bool offline) {
    _emit(_current.copyWith(
      cellularConnected: !offline,
      networkType: offline ? NetworkType.none : NetworkType.cellular4g,
      signalStrength: offline ? 0 : 4,
    ));
  }

  void setGnssOffline(bool offline) {
    _emit(_current.copyWith(gnssAvailable: !offline, gnssFix: !offline));
  }

  void setAdxl375Offline(bool offline) {
    _emit(_current.copyWith(adxl375Connected: !offline));
  }

  void setLsm6ds3Offline(bool offline) {
    _emit(_current.copyWith(lsm6ds3Connected: !offline));
  }

  void _emit(DeviceStatus next) {
    _current = next.copyWith(lastSeen: DateTime.now());
    _controller.add(_current);
  }
}
