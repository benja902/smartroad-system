import 'package:flutter/widgets.dart';

import 'package:smartroad/repositories/mock/mock_auth_repository.dart';
import 'package:smartroad/repositories/mock/mock_device_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/repositories/mock/mock_vehicle_repository.dart';
import 'package:smartroad/state/app_providers.dart';

/// Wraps [child] with AppProviders backed entirely by fresh Mock
/// repositories, so widget tests never touch a real Firebase app (which
/// isn't initialized in the test environment).
AppProviders mockAppProviders({required Widget child}) {
  return AppProviders(
    authRepository: MockAuthRepository(),
    deviceRepository: MockDeviceRepository(),
    eventRepository: MockEventRepository(),
    vehicleRepository: MockVehicleRepository(),
    child: child,
  );
}
