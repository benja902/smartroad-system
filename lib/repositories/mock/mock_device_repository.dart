import 'dart:async';

import '../../models/device_operational_state.dart';
import '../../models/device_status.dart';
import '../../models/gnss_position.dart';
import '../../models/modem_status.dart';
import '../../models/sensor_diagnostics.dart';
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
    _emit(_current.copyWith(
      online: operational,
      state: operational ? DeviceOperationalState.idle : DeviceOperationalState.safeMode,
    ));
  }

  void setDeviceOffline(bool offline) {
    _emit(_current.copyWith(online: !offline));
  }

  void setCellularOffline(bool offline) {
    final modem = _current.modem;
    _emit(_current.copyWith(
      modem: ModemStatus(
        registered: !offline,
        tech: offline ? null : (modem?.tech ?? 'LTE'),
        operatorName: offline ? null : (modem?.operatorName ?? 'Claro PE'),
        rssiDbm: offline ? null : (modem?.rssiDbm ?? -73),
      ),
    ));
  }

  void setGnssOffline(bool offline) {
    _emit(_current.copyWith(
      gnss: offline
          ? const GnssPosition(fix: false, latitude: 0, longitude: 0)
          : MockDataSeed.initialPosition,
    ));
  }

  void setAdxl375Offline(bool offline) {
    final current = _current.adxl375;
    _emit(_current.copyWith(
      adxl375: AdxlSensorStatus(ok: !offline, address: current?.address, peakG60s: current?.peakG60s),
    ));
  }

  void setLsm6ds3Offline(bool offline) {
    final current = _current.lsm6ds3;
    _emit(_current.copyWith(
      lsm6ds3: ImuSensorStatus(
        ok: !offline,
        address: current?.address,
        tiltDeg: current?.tiltDeg,
        gyroMaxDps: current?.gyroMaxDps,
      ),
    ));
  }

  void _emit(DeviceStatus next) {
    _current = next.copyWith(lastSeen: DateTime.now());
    _controller.add(_current);
  }
}
