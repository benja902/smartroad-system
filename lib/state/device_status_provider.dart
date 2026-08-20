import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device_status.dart';
import '../repositories/device_repository.dart';

/// Reactive to the signed-in user's primary vehicle: call [setDeviceId]
/// whenever VehicleProvider's vehicle changes (see AppProviders), since the
/// real deviceId is only known once the user's vehicle is resolved.
class DeviceStatusProvider extends ChangeNotifier {
  final DeviceRepository _deviceRepository;
  StreamSubscription<DeviceStatus>? _subscription;
  String? _deviceId;

  DeviceStatus? _status;
  DeviceStatus? get status => _status;

  DeviceStatusProvider(this._deviceRepository);

  void setDeviceId(String? deviceId) {
    if (_deviceId == deviceId) return;
    _deviceId = deviceId;

    _subscription?.cancel();
    _status = null;

    if (deviceId == null) {
      notifyListeners();
      return;
    }

    _subscription = _deviceRepository.watchStatus(deviceId).listen((status) {
      _status = status;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
