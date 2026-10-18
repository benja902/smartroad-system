import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/navigation/navigation_visual_preview.dart';
import 'package:smartroad/repositories/device_repository.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_device_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/home/home_visual_preview.dart';
import 'package:smartroad/screens/home/premium_home_content.dart';
import 'package:smartroad/screens/profile/profile_screen_placeholder.dart';
import 'package:smartroad/widgets/profile_header_action.dart';

import 'home_visual_preview_test.dart' show app, chooseHome;

void main() {
  testWidgets(
    'Profile header supports keyboard and system back returns to origin',
    (tester) async {
      await app(tester);
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-3')));
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.byIcon(Icons.person_outline_rounded)))
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreenPlaceholder), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .selectedIndex,
        3,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (var index = 0; index < 4; index++) {
    testWidgets(
      'DEV Profile returns to origin branch $index without rebuilding shell',
      (tester) async {
        await app(tester);
        await chooseHome(tester, HomePreviewVariant.routeStudio);
        await tester.tap(find.byKey(ValueKey('premium-nav-item-$index')));
        await tester.pumpAndSettle();
        final shell = tester.state(find.byType(StatefulNavigationShell));
        final bar = tester.widget<PremiumNavigationPreviewBar>(
          find.byType(PremiumNavigationPreviewBar),
        );
        expect(bar.destinations.map((d) => d.label), [
          'Inicio',
          'Alertas',
          'Vehículo',
          'Historial',
        ]);
        expect(bar.selectedIndex, index);
        final action = find.byType(ProfileHeaderAction);
        expect(action, findsOneWidget);
        expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreenPlaceholder), findsOneWidget);
        expect(find.byType(PremiumNavigationPreviewBar), findsNothing);
        final context = tester.element(find.byType(ProfileScreenPlaceholder));
        expect(GoRouterState.of(context).uri.path, '/profile');
        (context.read<DeviceRepository>() as MockDeviceRepository)
            .setDeviceOffline(true);
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(StatefulNavigationShell)), same(shell));
        expect(
          tester
              .widget<PremiumNavigationPreviewBar>(
                find.byType(PremiumNavigationPreviewBar),
              )
              .selectedIndex,
          index,
        );
        expect(find.byKey(const ValueKey('premium-nav-item-4')), findsNothing);
        expect(find.byType(ProfileHeaderAction), findsOneWidget);
        if (index == 0) {
          expect(find.text('SDA reportado desconectado'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Profile from Alertas preserves Home scroll and ongoing provider updates',
    (tester) async {
      await app(tester);
      await chooseHome(tester, HomePreviewVariant.routeStudio);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offset = scroll.position.pixels;
      expect(offset, greaterThan(0));
      final home = tester.element(find.byType(PremiumHomeContent));
      final events = home.read<EventRepository>() as MockEventRepository;
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProfileHeaderAction));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-0')));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable).first),
        same(scroll),
      );
      expect(scroll.position.pixels, offset);
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProfileHeaderAction));
      await tester.pumpAndSettle();
      events.triggerSos();
      await tester.pumpAndSettle();
      expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
      expect(find.byType(ProfileScreenPlaceholder), findsNothing);
      expect(find.byType(PremiumNavigationPreviewBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('MAIN keeps Profile as fifth branch and no new header actions', (
    tester,
  ) async {
    await app(tester, dev: false);
    expect(
      tester
          .widget<PremiumNavigationPreviewBar>(
            find.byType(PremiumNavigationPreviewBar),
          )
          .destinations
          .length,
      5,
    );
    expect(find.byType(ProfileHeaderAction), findsNothing);
    await tester.tap(find.byKey(const ValueKey('premium-nav-item-4')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreenPlaceholder), findsOneWidget);
    expect(
      tester
          .widget<PremiumNavigationPreviewBar>(
            find.byType(PremiumNavigationPreviewBar),
          )
          .selectedIndex,
      4,
    );
    expect(find.byTooltip('Back'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets(
      'Four DEV destinations and header actions at $width dp, 200% text and reduced motion',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await app(tester);
        await chooseHome(tester, HomePreviewVariant.routeStudio);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpAndSettle();
        for (var index = 0; index < 4; index++) {
          final item = find.byKey(ValueKey('premium-nav-item-$index'));
          await tester.tap(item);
          await tester.pumpAndSettle();
          expect(tester.getSize(item).shortestSide, greaterThanOrEqualTo(48));
          final action = find.byType(ProfileHeaderAction);
          expect(action, findsOneWidget);
          expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
          await tester.tap(action);
          await tester.pumpAndSettle();
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<PremiumNavigationPreviewBar>(
                  find.byType(PremiumNavigationPreviewBar),
                )
                .selectedIndex,
            index,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
