import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../models/accident_level.dart';
import '../models/event_status.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen_placeholder.dart';
import '../screens/contacts/contacts_screen_placeholder.dart';
import '../screens/dev/dev_simulator_screen.dart';
import '../screens/emergency/level2_screen.dart';
import '../screens/emergency/level3_screen.dart';
import '../screens/history/history_screen_placeholder.dart';
import '../screens/home/home_screen.dart';
import '../screens/incident_detail/incident_detail_screen_placeholder.dart';
import '../screens/profile/profile_screen_placeholder.dart';
import '../screens/vehicle/vehicle_screen_placeholder.dart';
import '../state/event_provider.dart';
import '../state/session_provider.dart';
import 'main_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/home';
  static const alerts = '/alerts';
  static const vehicle = '/vehicle';
  static const history = '/history';
  static const profile = '/profile';
  static const login = '/login';
  static const register = '/register';
  static const contacts = '/contacts';
  static const incidentDetail = '/incident';
  static const emergencyLevel2 = '/emergency/level2';
  static const emergencyLevel3 = '/emergency/level3';
  static const dev = '/dev';
}

class AppRouter {
  AppRouter._();

  /// Builds the go_router config. [includeDevRoute] must stay false in the
  /// production entrypoint (main.dart) — only main_dev.dart passes true, so
  /// /dev is physically absent from release route tables.
  static GoRouter build({
    required EventProvider eventProvider,
    required SessionProvider sessionProvider,
    bool includeDevRoute = false,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: Listenable.merge([eventProvider, sessionProvider]),
      redirect: (context, state) {
        final location = state.matchedLocation;
        final onAuthRoute = location == AppRoutes.login || location == AppRoutes.register;

        // Auth gate takes priority: an unauthenticated user can't reach any
        // screen (including a critical one) except login/register.
        if (!sessionProvider.isSignedIn) {
          return onAuthRoute ? null : AppRoutes.login;
        }
        if (onAuthRoute) {
          return AppRoutes.home;
        }

        final event = eventProvider.criticalEvent;
        final onEmergencyRoute =
            location == AppRoutes.emergencyLevel2 || location == AppRoutes.emergencyLevel3;

        if (event != null &&
            event.level == AccidentLevel.level3 &&
            event.status != EventStatus.closed) {
          return location == AppRoutes.emergencyLevel3 ? null : AppRoutes.emergencyLevel3;
        }

        if (event != null &&
            event.level == AccidentLevel.level2 &&
            (event.status == EventStatus.pendingConfirmation ||
                event.status == EventStatus.confirmed)) {
          return location == AppRoutes.emergencyLevel2 ? null : AppRoutes.emergencyLevel2;
        }

        if (event == null && onEmergencyRoute) {
          return AppRoutes.home;
        }

        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: AppRoutes.alerts, builder: (context, state) => const AlertsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.vehicle,
                builder: (context, state) => const VehicleScreenPlaceholder(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreenPlaceholder(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreenPlaceholder(),
              ),
            ]),
          ],
        ),
        GoRoute(
          path: AppRoutes.emergencyLevel2,
          builder: (context, state) => const Level2Screen(),
        ),
        GoRoute(
          path: AppRoutes.emergencyLevel3,
          builder: (context, state) => const Level3Screen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreenPlaceholder(),
        ),
        GoRoute(
          path: AppRoutes.contacts,
          builder: (context, state) => const ContactsScreenPlaceholder(),
        ),
        GoRoute(
          path: '${AppRoutes.incidentDetail}/:eventId',
          builder: (context, state) => IncidentDetailScreenPlaceholder(
            eventId: state.pathParameters['eventId']!,
          ),
        ),
        if (includeDevRoute)
          GoRoute(
            path: AppRoutes.dev,
            builder: (context, state) => const DevSimulatorScreen(),
          ),
      ],
    );
  }
}
