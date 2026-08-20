import 'package:flutter/material.dart';

import 'app.dart';
import 'repositories/mock/mock_auth_repository.dart';
import 'repositories/mock/mock_device_repository.dart';
import 'repositories/mock/mock_event_repository.dart';
import 'repositories/mock/mock_vehicle_repository.dart';
import 'state/app_providers.dart';

/// Development entrypoint: run with `flutter run -t lib/main_dev.dart`.
/// Adds the /dev route on top of the app and, crucially, backs it entirely
/// with Mock repositories — the /dev simulator panel casts to the concrete
/// Mock types to call simulator-only methods (triggerLevel2, setGnssOffline,
/// etc.), so it only makes sense paired with mocks. This intentionally does
/// NOT touch Firebase: the whole point of this entrypoint is demonstrating
/// the system without hardware or a network connection. Never referenced by
/// main.dart, so a release build (which always uses main.dart and real
/// Firebase) cannot reach /dev.
void main() {
  runApp(
    AppProviders(
      authRepository: MockAuthRepository(),
      deviceRepository: MockDeviceRepository(),
      eventRepository: MockEventRepository(),
      vehicleRepository: MockVehicleRepository(),
      child: const UrbesApp(includeDevRoute: true),
    ),
  );
}
