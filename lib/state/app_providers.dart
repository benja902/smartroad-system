import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../repositories/auth_repository.dart';
import '../repositories/device_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_contact_relation_repository.dart';
import '../repositories/firebase/firebase_device_repository.dart';
import '../repositories/firebase/firebase_event_repository.dart';
import '../repositories/firebase/firebase_vehicle_repository.dart';
import '../repositories/vehicle_repository.dart';
import 'device_status_provider.dart';
import 'event_provider.dart';
import 'session_provider.dart';
import 'vehicle_provider.dart';
import 'access_context_provider.dart';

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
  final PendingInvitationReader? pendingInvitationReader;

  /// DEV explicitly keeps its existing mock composition.
  final bool enforceAccess;

  const AppProviders({
    super.key,
    required this.child,
    this.authRepository,
    this.deviceRepository,
    this.eventRepository,
    this.vehicleRepository,
    this.pendingInvitationReader,
    this.enforceAccess = true,
  });

  @override
  Widget build(BuildContext context) {
    if (enforceAccess) return _restrictedEntry();
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => authRepository ?? FirebaseAuthRepository(),
        ),
        Provider<DeviceRepository>(
          create: (_) => deviceRepository ?? FirebaseDeviceRepository(),
        ),
        Provider<EventRepository>(
          create: (_) => eventRepository ?? FirebaseEventRepository(),
        ),
        Provider<VehicleRepository>(
          create: (_) => vehicleRepository ?? FirebaseVehicleRepository(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SessionProvider(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProxyProvider<SessionProvider, VehicleProvider>(
          create: (ctx) => VehicleProvider(ctx.read<VehicleRepository>()),
          update: (ctx, session, vehicleProvider) =>
              vehicleProvider!..setUserId(session.user?.id),
        ),
        ChangeNotifierProxyProvider2<
          SessionProvider,
          VehicleProvider,
          EventProvider
        >(
          create: (ctx) => EventProvider(ctx.read<EventRepository>()),
          update: (ctx, session, vehicle, eventProvider) => eventProvider!
            ..setContext(
              userId: session.user?.id,
              vehicleId: vehicle.vehicle?.id,
            ),
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

  Widget _restrictedEntry() => MultiProvider(
    providers: [
      Provider<AuthRepository>(
        create: (_) => authRepository ?? FirebaseAuthRepository(),
      ),
      Provider<VehicleRepository>(
        create: (_) => vehicleRepository ?? FirebaseVehicleRepository(),
      ),
      Provider<PendingInvitationReader>(
        create: (_) =>
            pendingInvitationReader ??
            FirebaseContactRelationRepository()
                .watchPendingInvitationResolution,
      ),
      ChangeNotifierProvider(
        create: (ctx) => SessionProvider(ctx.read<AuthRepository>()),
      ),
      ChangeNotifierProxyProvider<SessionProvider, AccessContextProvider>(
        create: (ctx) {
          final repository = ctx.read<VehicleRepository>();
          return AccessContextProvider(
            repository is FirebaseVehicleRepository
                ? repository.watchOwnerResolution
                : (uid) => repository
                      .watchPrimaryVehicle(uid)
                      .map((vehicle) => (loading: false, vehicle: vehicle)),
          );
        },
        update: (_, session, access) =>
            access!..setSession(session.user?.id, error: session.error),
      ),
    ],
    child: Consumer<AccessContextProvider>(
      builder: (context, access, _) {
        final owner = access.status == AccessStatus.owner;
        return KeyedSubtree(
          key: ValueKey('${owner ? 'owner' : 'entry'}:${access.userId}'),
          child: owner
              ? MultiProvider(
                  providers: [
                    Provider<DeviceRepository>(
                      create: (_) =>
                          deviceRepository ?? FirebaseDeviceRepository(),
                    ),
                    Provider<EventRepository>(
                      create: (_) =>
                          eventRepository ?? FirebaseEventRepository(),
                    ),
                    ChangeNotifierProxyProvider<
                      AccessContextProvider,
                      VehicleProvider
                    >(
                      create: (ctx) =>
                          VehicleProvider(ctx.read<VehicleRepository>()),
                      update: (_, current, vehicle) =>
                          vehicle!..setResolvedVehicle(current.vehicle),
                    ),
                    ChangeNotifierProxyProvider<
                      AccessContextProvider,
                      EventProvider
                    >(
                      create: (ctx) =>
                          EventProvider(ctx.read<EventRepository>()),
                      update: (_, current, events) => events!
                        ..setContext(
                          userId: current.userId,
                          vehicleId: current.vehicle?.id,
                        ),
                    ),
                    ChangeNotifierProxyProvider<
                      VehicleProvider,
                      DeviceStatusProvider
                    >(
                      create: (ctx) =>
                          DeviceStatusProvider(ctx.read<DeviceRepository>()),
                      update: (_, vehicle, device) =>
                          device!..setDeviceId(vehicle.vehicle?.deviceId),
                    ),
                  ],
                  child: child,
                )
              : child,
        );
      },
    ),
  );
}
