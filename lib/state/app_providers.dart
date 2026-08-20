import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../repositories/auth_repository.dart';
import '../repositories/device_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_device_repository.dart';
import '../repositories/firebase/firebase_event_repository.dart';
import '../repositories/firebase/firebase_vehicle_repository.dart';
import '../repositories/vehicle_repository.dart';
import 'device_status_provider.dart';
import 'event_provider.dart';
import 'session_provider.dart';
import 'vehicle_provider.dart';

/// Single composition root for dependency injection. Repositories default
/// to their Firebase implementations; tests (and any future alternate
/// entrypoint) inject Mock implementations explicitly via the constructor
/// instead of relying on a build-time flag, so no test needs a real
/// Firebase app initialized.
///
/// Wiring below the repository layer is reactive to sign-in: EventProvider
/// and VehicleProvider only start watching data once SessionProvider
/// resolves a user (real userId, not a hardcoded one), and
/// DeviceStatusProvider only starts once VehicleProvider resolves that
/// user's primary vehicle (real deviceId). This is required for Firebase —
/// userId/deviceId aren't known until auth/vehicle data actually loads —
/// and is harmless for the mocks, which ignore the ids they're given.
class AppProviders extends StatelessWidget {
  final Widget child;
  final AuthRepository? authRepository;
  final DeviceRepository? deviceRepository;
  final EventRepository? eventRepository;
  final VehicleRepository? vehicleRepository;

  const AppProviders({
    super.key,
    required this.child,
    this.authRepository,
    this.deviceRepository,
    this.eventRepository,
    this.vehicleRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => authRepository ?? FirebaseAuthRepository()),
        Provider<DeviceRepository>(create: (_) => deviceRepository ?? FirebaseDeviceRepository()),
        Provider<EventRepository>(create: (_) => eventRepository ?? FirebaseEventRepository()),
        Provider<VehicleRepository>(create: (_) => vehicleRepository ?? FirebaseVehicleRepository()),
        ChangeNotifierProvider(
          create: (ctx) => SessionProvider(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProxyProvider<SessionProvider, EventProvider>(
          create: (ctx) => EventProvider(ctx.read<EventRepository>()),
          update: (ctx, session, eventProvider) => eventProvider!..setUserId(session.user?.id),
        ),
        ChangeNotifierProxyProvider<SessionProvider, VehicleProvider>(
          create: (ctx) => VehicleProvider(ctx.read<VehicleRepository>()),
          update: (ctx, session, vehicleProvider) => vehicleProvider!..setUserId(session.user?.id),
        ),
        ChangeNotifierProxyProvider<VehicleProvider, DeviceStatusProvider>(
          create: (ctx) => DeviceStatusProvider(ctx.read<DeviceRepository>()),
          update: (ctx, vehicle, deviceStatusProvider) =>
              deviceStatusProvider!..setDeviceId(vehicle.vehicle?.deviceId),
        ),
      ],
      child: child,
    );
  }
}
