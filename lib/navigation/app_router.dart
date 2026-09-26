import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../models/alert_presentation.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen_placeholder.dart';
import '../screens/contacts/contacts_screen_placeholder.dart';
import '../screens/dev/dev_simulator_screen.dart';
import '../screens/emergency/active_emergency_screen.dart';
import '../screens/history/history_screen_placeholder.dart';
import '../screens/home/home_screen.dart';
import '../screens/incident_detail/incident_detail_screen_placeholder.dart';
import '../screens/profile/profile_screen_placeholder.dart';
import '../screens/vehicle/vehicle_screen_placeholder.dart';
import '../state/event_provider.dart';
import '../state/session_provider.dart';
import 'dev_navigation_override.dart';
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
  static const activeEmergency = '/emergency/active';
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
    DevNavigationOverride? devOverride,
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
        final onEmergencyRoute = location == AppRoutes.activeEmergency;
        final onDevRoute = location == AppRoutes.dev;

        // shouldForceCriticalScreen (not clasificar(...) == ...) on purpose —
        // keeps presentation and interruption behavior decoupled.
        if (event != null && shouldForceCriticalScreen(event)) {
          // Dev-only escape hatch: "Volver a /dev" sets devOverride.eventKey
          // to the event it left behind, so returning to /dev for THAT
          // specific event isn't immediately bounced back. A genuinely new
          // critical event (different dedupKey) still forces navigation to
          // the emergency screen even while /dev is open — this only
          // suppresses the redirect for the exact event you dismissed to
          // go inspect /dev, not forever. Harmless in production: /dev
          // isn't a registered route there, so onDevRoute is never true.
          final devOverrideActive = onDevRoute && devOverride?.eventKey == event.dedupKey;
          return (onEmergencyRoute || devOverrideActive) ? null : AppRoutes.activeEmergency;
        }

        devOverride?.eventKey = null;

        if (onEmergencyRoute) {
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
          path: AppRoutes.activeEmergency,
          builder: (context, state) => const ActiveEmergencyScreen(),
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
