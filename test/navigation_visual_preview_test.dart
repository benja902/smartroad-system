import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/app.dart';
import 'package:smartroad/core/theme/app_theme.dart';
import 'package:smartroad/main_dev.dart' as dev_entry;
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/navigation/navigation_visual_preview.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/dev/dev_navigation_review.dart';
import 'package:smartroad/screens/home/home_screen.dart';
import 'package:smartroad/widgets/screen_entrance.dart';

import 'test_helpers.dart';
import 'premium_login_test.dart' show fill;

const destinations = [
  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
  NavigationDestination(
    icon: Icon(Icons.notifications_outlined),
    label: 'Alertas',
  ),
  NavigationDestination(
    icon: Icon(Icons.directions_car_outlined),
    label: 'Vehículo',
  ),
  NavigationDestination(icon: Icon(Icons.history_outlined), label: 'Historial'),
  NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
];

Future<void> choose(
  WidgetTester tester,
  NavigationPreviewVariant variant,
) async {
  await tester.tap(find.byKey(const ValueKey('dev-nav-variant-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, variant.label));
  await tester.pumpAndSettle();
}

Future<GlobalKey> review(WidgetTester tester, {bool dev = true}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    mockAppProviders(
      child: UrbesApp(
        key: key,
        includeDevRoute: dev,
        devBuilder: (context, child) => DevNavigationReview(child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  testWidgets(
    'Real DEV startup preserves D/Login and nav choice across logout without replay',
    (tester) async {
      await dev_entry.main();
      await tester.pump();
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.tap(find.text('Omitir introducción'));
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .variant,
        NavigationPreviewVariant.pillActive,
      );
      await choose(tester, NavigationPreviewVariant.pillActive);
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Omitir introducción'), findsNothing);
      expect(find.byType(PremiumNavigationPreviewBar), findsNothing);
      await fill(tester);
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .variant,
        NavigationPreviewVariant.pillActive,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final variant in [
    NavigationPreviewVariant.underline,
    NavigationPreviewVariant.pillActive,
  ]) {
    testWidgets(
      '${variant.name}: one retained shell, all branches, animated indicator and content',
      (tester) async {
        await review(tester);
        await choose(tester, variant);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
        await tester.pumpAndSettle();
        final scrollState = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        final offset = scrollState.position.pixels;
        final entrance = tester.state(find.byType(ScreenEntrance));
        final containerBefore = tester.getRect(
          find.byKey(const ValueKey('premium-nav-container')),
        );
        final indicator = find.byKey(const ValueKey('premium-nav-indicator'));
        final indicatorBefore = tester.getRect(indicator);
        await tester.tap(find.byKey(const ValueKey('premium-nav-item-1')));
        await tester.pump();
        expect(
          tester
              .widget<PremiumNavigationPreviewBar>(
                find.byType(PremiumNavigationPreviewBar),
              )
              .selectedIndex,
          1,
        );
        expect(tester.getRect(indicator), indicatorBefore);
        final motion = find.byKey(const ValueKey('premium-nav-content-motion'));
        expect(tester.widget<Transform>(motion).transform.entry(0, 3), 6);
        await tester.pump(const Duration(milliseconds: 90));
        expect(
          tester.getRect(indicator).left,
          greaterThan(indicatorBefore.left),
        );
        expect(
          tester.widget<Transform>(motion).transform.entry(0, 3),
          closeTo(.75, .01),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Transform>(motion).transform.entry(0, 3), 0);
        for (final index in [2, 3, 4, 0]) {
          await tester.tap(find.byKey(ValueKey('premium-nav-item-$index')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<PremiumNavigationPreviewBar>(
                  find.byType(PremiumNavigationPreviewBar),
                )
                .selectedIndex,
            index,
          );
          expect(find.byType(StatefulNavigationShell), findsOneWidget);
        }
        expect(scrollState.position.pixels, offset);
        expect(tester.state(find.byType(ScreenEntrance)), same(entrance));
        expect(
          tester.getRect(find.byKey(const ValueKey('premium-nav-container'))),
          containerBefore,
        );
        await choose(tester, NavigationPreviewVariant.current);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(scrollState.position.pixels, offset);
        await choose(tester, variant);
        expect(scrollState.position.pixels, offset);
        expect(tester.takeException(), isNull);
      },
    );

    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${variant.name}: ${width.toInt()} dp / ${scale * 100}% / safe area',
          (tester) async {
            tester.view.physicalSize = Size(width, 640);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(bottom: 24);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                home: Scaffold(
                  bottomNavigationBar: PremiumNavigationPreviewBar(
                    variant: variant,
                    destinations: destinations,
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final bar = tester.getRect(
              find.byKey(const ValueKey('premium-nav-container')),
            );
            expect(bar.left, greaterThanOrEqualTo(12));
            expect(bar.right, lessThanOrEqualTo(width - 12));
            expect(bar.bottom, lessThanOrEqualTo(640 - 24 - 12));
            for (var i = 0; i < 5; i++) {
              final item = find.byKey(ValueKey('premium-nav-item-$i'));
              final bounds = tester.getRect(item);
              expect(bounds.width, greaterThanOrEqualTo(48));
              expect(bounds.height, greaterThanOrEqualTo(48));
              final label = tester.getRect(find.text(destinations[i].label));
              expect(label.left, greaterThanOrEqualTo(bounds.left));
              expect(label.right, lessThanOrEqualTo(bounds.right));
              expect(label.bottom, lessThanOrEqualTo(bounds.bottom));
              final semantics = tester.widget<Semantics>(
                find
                    .descendant(of: item, matching: find.byType(Semantics))
                    .first,
              );
              expect(semantics.properties.label, destinations[i].label);
              expect(semantics.properties.button, true);
              expect(semantics.properties.selected, i == 0);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'Keyboard activates the real callbacks and touch feedback responds while pressed',
    (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            bottomNavigationBar: PremiumNavigationPreviewBar(
              variant: NavigationPreviewVariant.underline,
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (index) => selected = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 1);
      final target = find.byKey(const ValueKey('premium-nav-item-3'));
      final gesture = await tester.startGesture(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 110));
      final scale = tester.widget<AnimatedScale>(
        find.descendant(of: target, matching: find.byType(AnimatedScale)),
      );
      expect(scale.scale, .94);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reduced motion removes translations and movement at selection', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await review(tester);
    await tester.tap(find.byKey(const ValueKey('premium-nav-item-4')));
    await tester.pump();
    expect(
      tester
          .widget<PremiumNavigationPreviewBar>(
            find.byType(PremiumNavigationPreviewBar),
          )
          .selectedIndex,
      4,
    );
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('premium-nav-content-motion')),
          )
          .transform
          .entry(0, 3),
      0,
    );
    expect(
      tester
          .widget<AnimatedPositioned>(
            find.byKey(const ValueKey('premium-nav-indicator')),
          )
          .duration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Critical route preempts a running tab transition and hides navigation',
    (tester) async {
      final key = await review(tester);
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-1')));
      await tester.pump();
      (key.currentContext!.read<EventRepository>() as MockEventRepository)
          .triggerSos();
      await tester.pumpAndSettle();
      expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
      expect(find.byType(PremiumNavigationPreviewBar), findsNothing);
      expect(find.byKey(const ValueKey('dev-nav-variant-menu')), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Enabling reduced motion during travel snaps to final state without losing shell',
    (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await review(tester);
      final shellState = tester.state(find.byType(StatefulNavigationShell));
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-4')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 45));
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('premium-nav-content-motion')),
            )
            .transform
            .entry(0, 3),
        greaterThan(0),
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pump();
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('premium-nav-content-motion')),
            )
            .transform
            .entry(0, 3),
        0,
      );
      final indicator = find.byKey(const ValueKey('premium-nav-indicator'));
      final atRest = tester.getRect(indicator);
      expect(
        tester.widget<AnimatedPositioned>(indicator).duration,
        Duration.zero,
      );
      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.getRect(indicator), atRest);
      expect(
        tester.state(find.byType(StatefulNavigationShell)),
        same(shellState),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Rapid selection retargets the indicator and repeated active tap does not replay content',
    (tester) async {
      await review(tester);
      for (final index in [4, 1, 3, 0]) {
        await tester.tap(find.byKey(ValueKey('premium-nav-item-$index')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .selectedIndex,
        0,
      );
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-0')));
      await tester.pump();
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('premium-nav-content-motion')),
            )
            .transform
            .entry(0, 3),
        0,
      );
      expect(find.byType(StatefulNavigationShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Production defaults to Pill Active and ignores experimental review choices',
    (tester) async {
      await tester.pumpWidget(
        mockAppProviders(
          child: UrbesApp(
            devBuilder: (context, child) => NavigationVisualPreview(
              variant: NavigationPreviewVariant.underline,
              reviewAction: const Text('DEV only'),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .variant,
        NavigationPreviewVariant.pillActive,
      );
      expect(find.byType(NavigationPreviewContentMotion), findsOneWidget);
      expect(find.byKey(const ValueKey('dev-nav-variant-menu')), findsNothing);
      expect(find.byTooltip('Panel de desarrollo'), findsNothing);
    },
  );

  testWidgets(
    'Ordinary app without DEV scope uses Pill Active and preserves branch selection',
    (tester) async {
      await tester.pumpWidget(mockAppProviders(child: const UrbesApp()));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .variant,
        NavigationPreviewVariant.pillActive,
      );
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-2')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .selectedIndex,
        2,
      );
      expect(find.byKey(const ValueKey('dev-nav-variant-menu')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
