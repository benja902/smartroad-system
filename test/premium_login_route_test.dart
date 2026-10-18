import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/app.dart';
import 'package:smartroad/state/app_providers.dart';
import 'package:smartroad/repositories/mock/mock_auth_repository.dart';
import 'package:smartroad/repositories/mock/mock_device_repository.dart';
import 'package:smartroad/repositories/mock/mock_vehicle_repository.dart';
import 'package:smartroad/screens/dev/brand_intro/dev_brand_intro.dart';
import 'package:smartroad/presentation/premium_scene/premium_scene.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/screens/auth/premium_login_presentation.dart';
import 'package:smartroad/screens/dev/premium_login_preview.dart';
import 'package:smartroad/state/session_provider.dart';

import 'premium_login_test.dart' show fill;
import 'test_helpers.dart';

Future<GlobalKey> openRouted(
  WidgetTester tester, {
  bool visualReview = false,
}) async {
  final key = GlobalKey();
  final auth = MockAuthRepository();
  await auth.signOut();
  // Exercise actual DEV startup; signing out an existing session is not startup.
  await tester.pumpWidget(
    AppProviders(
      authRepository: auth,
      deviceRepository: MockDeviceRepository(),
      eventRepository: MockEventRepository(),
      vehicleRepository: MockVehicleRepository(),
      child: ChangeNotifierProvider(
        create: (_) => DevBrandIntroController(),
        child: UrbesApp(
          key: key,
          includeDevRoute: true,
          devBuilder: (context, child) => DevBrandIntroHost(
            premiumLoginOnStartup: true,
            enableLoginVisualReview: visualReview,
            firstFrameReady: Future<void>.value(),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return key;
}

Future<void> submit(WidgetTester tester) async {
  await fill(tester);
  await tester.ensureVisible(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Profile logout returns directly to final premium Login; manual replay still works',
    (tester) async {
      final key = await openRouted(tester);
      await tester.pumpAndSettle();
      await submit(tester);
      expect(key.currentContext!.read<SessionProvider>().isSignedIn, true);
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pump();
      await tester.pump();
      expect(key.currentContext!.read<SessionProvider>().isSignedIn, false);
      expect(find.byType(LoginScreen), findsOneWidget);
      final timeline = PremiumLoginTimeline.maybeOf(
        tester.element(find.byType(LoginScreen)),
      )!;
      expect(timeline.progress, same(PremiumLoginTimeline.completed));
      expect(find.byType(Form), findsOneWidget);
      expect(
        find.byKey(const ValueKey('signature-login-panel')),
        findsOneWidget,
      );
      expect(find.text('Omitir introducción'), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      expect(timeline.progress.value, 4440 / 2600);
      await submit(tester);
      await tester.tap(find.byTooltip('Panel de desarrollo'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Reproducir Splash → Login real DEV'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reproducir Splash → Login real DEV'));
      await tester.pump();
      await tester.pump();
      final preview = tester.widget<DevPremiumLoginPreview>(
        find.byType(DevPremiumLoginPreview),
      );
      expect(preview.progress.value, 0);
      await tester.pump(const Duration(milliseconds: 400));
      expect(preview.progress.value, greaterThan(0));
      expect(find.byType(Form), findsNothing);
      await tester.tap(find.text('Omitir introducción'));
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
      await tester.tap(find.text('Cerrar DEV'));
      await tester.pumpAndSettle();
      expect(key.currentContext!.read<SessionProvider>().isSignedIn, true);
    },
  );
  testWidgets(
    'Real DEV route runs D, mounts one form at handoff and signs into the app session',
    (tester) async {
      final key = await openRouted(tester);
      final session = key.currentContext!.read<SessionProvider>();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DevPremiumLoginPreview), findsNothing);
      expect(find.byType(Form), findsNothing);
      final context = tester.element(find.byType(LoginScreen));
      expect(context.read<SessionProvider>(), same(session));
      final clock = PremiumLoginTimeline.maybeOf(context)!.progress;
      expect(clock.value, 0);
      await tester.pump(const Duration(milliseconds: 4080));
      expect(find.byType(Form), findsNothing);
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(Form), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 350));
      expect(clock.value, 4440 / 2600);
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((p) => p.painter is PremiumClosureBrandPainter),
        hasLength(1),
      );
      await submit(tester);
      expect(session.user?.email, 'pilot@example.invalid');
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byTooltip('Panel de desarrollo'), findsOneWidget);
    },
  );

  testWidgets(
    'Ordinary route uses the same premium form without enabling production Splash',
    (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
      await tester.pumpAndSettle();
      await key.currentContext!.read<SessionProvider>().signOut();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PremiumLoginPresentation), findsOneWidget);
      expect(
        find.byKey(const ValueKey('signature-login-panel')),
        findsOneWidget,
      );
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Omitir introducción'), findsNothing);
      expect(find.byType(DevPremiumLoginPreview), findsNothing);
      expect(
        PremiumLoginTimeline.maybeOf(tester.element(find.byType(LoginScreen))),
        isNull,
      );
      await submit(tester);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byTooltip('Panel de desarrollo'), findsNothing);
    },
  );

  testWidgets(
    'Omit and background retain actual fields and never replay on resume',
    (tester) async {
      await openRouted(tester);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Omitir introducción'));
      await tester.pumpAndSettle();
      await fill(tester);
      final context = tester.element(find.byType(LoginScreen));
      final clock = PremiumLoginTimeline.maybeOf(context)!.progress;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(clock.value, 4440 / 2600);
      expect(find.byType(Form), findsOneWidget);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .first
            .controller
            .text,
        'pilot@example.invalid',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Auth gate is preserved; a stored critical event opens immediately after sign-in',
    (tester) async {
      final key = await openRouted(tester);
      (key.currentContext!.read<EventRepository>() as MockEventRepository)
          .triggerSos();
      // EventProvider intentionally does not read incidents without a session.
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(Form), findsNothing);
      await tester.tap(find.text('Omitir introducción'));
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Omitir introducción'), findsNothing);
      expect(find.text('AUXILIO SOLICITADO'), findsNothing);
      await submit(tester);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
    },
  );

  testWidgets(
    'Reduced motion shows routed form immediately with no decorative wait',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await openRouted(tester);
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Omitir introducción'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
