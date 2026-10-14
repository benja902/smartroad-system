import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smartroad/app.dart';
import 'package:smartroad/core/theme/app_theme.dart';
import 'package:smartroad/repositories/device_repository.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_device_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/screens/home/widgets/quick_actions_row.dart';
import 'package:smartroad/state/session_provider.dart';
import 'package:smartroad/widgets/screen_entrance.dart';

import 'test_helpers.dart';

void main() {
  testWidgets(
    'Entrance finishes once; rebuilds and reduced motion never replay',
    (tester) async {
      late Animation<double> timeline;
      var taps = 0;
      Widget host(bool reduced) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: ScreenEntrance(
            builder: (context, animation) {
              timeline = animation;
              return EntranceSection(
                animation: animation,
                fade: true,
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Actuar'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpWidget(host(false));
      expect(timeline.value, 0);
      await tester.tap(find.text('Actuar'));
      expect(taps, 1);
      await tester.pump(const Duration(milliseconds: 80));
      expect(timeline.value, inExclusiveRange(0, 1));
      final before = timeline.value;
      await tester.pumpWidget(host(false));
      expect(timeline.value, before);
      await tester.pumpWidget(host(true));
      expect(timeline.value, 1);
      await tester.pumpWidget(host(false));
      expect(timeline.value, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(host(true));
      expect(timeline.value, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Login validates and authenticates during entrance with mocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      mockAppProviders(
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'pilot@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).last, 'demo-only');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    final session = tester
        .element(find.byType(LoginScreen))
        .read<SessionProvider>();
    expect(session.user?.email, 'pilot@example.invalid');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home updates and all five branches preserve timeline and scroll',
    (tester) async {
      await tester.pumpWidget(mockAppProviders(child: const UrbesApp()));
      await tester.pumpAndSettle();
      final section = tester.widget<EntranceSection>(
        find.byType(EntranceSection).first,
      );
      final timeline = section.animation;
      final context = tester.element(find.byType(UrbesApp));
      (context.read<DeviceRepository>() as MockDeviceRepository)
          .setDeviceOffline(true);
      await tester.pump();
      await tester.pump();
      expect(find.text('URBES con problemas'), findsOneWidget);
      expect(timeline.value, 1);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
      final scrollState = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offset = scrollState.position.pixels;
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      for (final index in [1, 2, 3, 4, 0]) {
        nav.onDestinationSelected!(index);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          index,
        );
      }
      expect(scrollState.position.pixels, offset);
      expect(timeline.value, 1);
      expect(timeline.status, AnimationStatus.completed);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Critical event interrupts Home while entrance is still running',
    (tester) async {
      await tester.pumpWidget(mockAppProviders(child: const UrbesApp()));
      await tester.pump();
      await tester.pump();
      final timeline = tester
          .widget<EntranceSection>(find.byType(EntranceSection).first)
          .animation;
      expect(timeline.value, lessThan(1));
      final context = tester.element(find.byType(UrbesApp));
      (context.read<EventRepository>() as MockEventRepository).triggerSos();
      await tester.pump();
      await tester.pump();
      expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Small login with large text and keyboard remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      mockAppProviders(
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 240),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Quick actions retain full labels and immediate taps with large text',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SizedBox(
                width: 280,
                child: QuickActionsRow(
                  actions: [
                    QuickAction(
                      icon: Icons.group_outlined,
                      label: 'Contactos de emergencia',
                      subtitle: 'Gestionar',
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Contactos de emergencia'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Small Home supports large text throughout its scroll content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(mockAppProviders(child: const UrbesApp()));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .animationDuration,
      Duration.zero,
    );
    for (
      var i = 0;
      i < 40 && find.text('Alertas recientes').evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Alertas recientes'), findsOneWidget);
  });
}
