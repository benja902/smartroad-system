import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'screens/dev/brand_intro/dev_brand_intro.dart';
import 'screens/dev/dev_navigation_review.dart';
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
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = MockAuthRepository();
  // Start the existing mock signed out so DEV exercises the real /login route.
  await auth.signOut();
  runApp(
    AppProviders(
      enforceAccess: false,
      authRepository: auth,
      deviceRepository: MockDeviceRepository(),
      eventRepository: MockEventRepository(),
      vehicleRepository: MockVehicleRepository(),
      child: ChangeNotifierProvider(
        create: (_) => DevBrandIntroController(),
        child: UrbesApp(
          includeDevRoute: true,
          devBuilder: (context, child) => DevBrandIntroHost(
            premiumLoginOnStartup: true,
            enableLoginVisualReview: true,
            child: DevNavigationReview(child: child!),
          ),
        ),
      ),
    ),
  );
}
