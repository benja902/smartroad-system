import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/navigation/navigation_visual_preview.dart';
import 'package:smartroad/screens/home/home_visual_preview.dart';
import 'package:smartroad/screens/profile/profile_screen_placeholder.dart';
import 'package:smartroad/widgets/pinned_profile_header.dart';
import 'package:smartroad/widgets/profile_header_action.dart';

import 'home_visual_preview_test.dart' show app, chooseHome;

void main() {
  for (final sample in [
    (320.0, 1.0, 1.0),
    (390.0, 2.0, 1.0),
    (484.0, 1.3, 1.49),
    (800.0, 1.3, 1.0),
  ]) {
    testWidgets(
      'Profile has one anchor across all tabs and transition frames: $sample',
      (tester) async {
        tester.view.physicalSize = Size(sample.$1 * sample.$3, 940 * sample.$3);
        tester.view.devicePixelRatio = sample.$3;
        tester.view.padding = FakeViewPadding(top: 24 * sample.$3);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await app(tester);
        await chooseHome(tester, HomePreviewVariant.routeStudio);
        tester.platformDispatcher.textScaleFactorTestValue = sample.$2;
        await tester.pumpAndSettle();
        final action = find.byType(ProfileHeaderAction);
        final anchor = tester.getRect(action);
        expect(anchor.top, closeTo(32, 1e-6));
        final height = tester
            .widget<SliverPersistentHeader>(find.byType(SliverPersistentHeader))
            .delegate
            .maxExtent;
        void expectAnchor() {
          final rect = tester.getRect(action);
          expect(rect.left, closeTo(anchor.left, 1e-6));
          expect(rect.top, closeTo(anchor.top, 1e-6));
          expect(rect.width, closeTo(anchor.width, 1e-6));
          expect(rect.height, closeTo(anchor.height, 1e-6));
          expect(find.byType(ProfileHeaderAction), findsOneWidget);
          expect(
            tester
                .widget<SliverPersistentHeader>(
                  find.byType(SliverPersistentHeader),
                )
                .delegate
                .maxExtent,
            height,
          );
        }

        for (final index in [1, 2, 3, 0]) {
          await tester.tap(find.byKey(ValueKey('premium-nav-item-$index')));
          await tester.pump();
          expectAnchor();
          await tester.pump(const Duration(milliseconds: 90));
          expectAnchor();
          await tester.pumpAndSettle();
          expectAnchor();
          expect(tester.takeException(), isNull);
        }
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreenPlaceholder), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expectAnchor();
      },
    );
  }
  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Pinned Profile survives Home and Alerts scroll at $width dp / $scale text',
        (tester) async {
          tester.view.physicalSize = Size(width, 640);
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
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpAndSettle();
          for (final index in [0, 1]) {
            await tester.tap(find.byKey(ValueKey('premium-nav-item-$index')));
            await tester.pumpAndSettle();
            expect(find.byType(PinnedProfileHeader), findsOneWidget);
            final action = find.byType(ProfileHeaderAction);
            expect(action, findsOneWidget);
            final rect = tester.getRect(action);
            final viewport = find.byType(CustomScrollView);
            final scroll = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            await tester.drag(viewport, const Offset(0, -500));
            await tester.pumpAndSettle();
            final offset = scroll.position.pixels;
            expect(offset, greaterThan(0));
            expect(tester.getRect(action), rect);
            expect(rect.top, greaterThanOrEqualTo(0));
            // Rect edge subtraction can introduce sub-pixel floating error.
            expect(rect.width, greaterThanOrEqualTo(48 - 1e-6));
            expect(rect.height, greaterThanOrEqualTo(48 - 1e-6));
            expect(find.byType(ProfileHeaderAction), findsOneWidget);
            if (index == 0) {
              expect(
                find.byKey(const ValueKey('guardian-official-brand')),
                findsOneWidget,
              );
              final greeting = find.text('Hola, Mariana');
              if (greeting.evaluate().isNotEmpty) {
                expect(
                  tester.getBottomLeft(greeting).dy,
                  lessThanOrEqualTo(rect.bottom),
                );
              }
            } else {
              // One section title in the pinned header, one label in Pill Active.
              expect(find.text('Alertas'), findsNWidgets(2));
            }
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(find.byType(ProfileScreenPlaceholder), findsOneWidget);
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(scroll.position.pixels, offset);
            expect(tester.getRect(action), rect);
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

  testWidgets(
    'MAIN keeps five destinations and its existing scrollable header',
    (tester) async {
      await app(tester, dev: false);
      expect(find.byType(PinnedProfileHeader), findsNothing);
      expect(find.byType(ProfileHeaderAction), findsNothing);
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .destinations
            .length,
        5,
      );
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-1')));
      await tester.pumpAndSettle();
      expect(find.byType(PinnedProfileHeader), findsNothing);
      expect(find.byType(ProfileHeaderAction), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
