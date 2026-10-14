import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smartroad/app.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/dev/brand_intro/dev_brand_intro.dart';

import 'test_helpers.dart';

Finder get scene => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is BrandIntroPainter,
);

Widget devBrandApp({Key? key, Future<void>? firstFrameReady}) =>
    mockAppProviders(
      child: ChangeNotifierProvider(
        create: (_) => DevBrandIntroController(),
        child: UrbesApp(
          key: key,
          includeDevRoute: true,
          devBuilder: (context, child) => DevBrandIntroHost(
            firstFrameReady: firstFrameReady ?? Future<void>.value(),
            child: child!,
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'DEV launch paints immediately, then finishes without navigation changes',
    (tester) async {
      await tester.pumpWidget(devBrandApp());
      await tester.pump();
      expect(scene, findsOneWidget);
      final first =
          (tester.widget<CustomPaint>(scene).painter! as BrandIntroPainter)
              .progress;
      expect(first.value, 0);
      await tester.pump(const Duration(milliseconds: 950));
      expect(first.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(scene, findsNothing);
      expect(find.text('Inicio'), findsOneWidget);
      await tester.tap(find.text('Alertas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      expect(scene, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A long startup frame cannot skip the road-to-shield sequence', (
    tester,
  ) async {
    await tester.pumpWidget(devBrandApp());
    await tester.pump();
    final progress =
        (tester.widget<CustomPaint>(scene).painter! as BrandIntroPainter)
            .progress;
    await tester.pump(const Duration(milliseconds: 16));
    final beforeStall = progress.value;

    // Simulate the reported cold-start pause after Flutter's first frame.
    await tester.pump(const Duration(milliseconds: 1800));
    expect(scene, findsOneWidget);
    expect(progress.value, lessThan(0.1));
    expect(progress.value, greaterThanOrEqualTo(beforeStall));

    await tester.pump(const Duration(milliseconds: 16));
    expect(progress.value, greaterThan(beforeStall));
    await tester.pumpAndSettle();
    expect(scene, findsNothing);
  });

  testWidgets('The timeline waits for the first visible Flutter frame', (
    tester,
  ) async {
    final ready = Completer<void>();
    await tester.pumpWidget(devBrandApp(firstFrameReady: ready.future));
    await tester.pump(const Duration(seconds: 2));
    final progress =
        (tester.widget<CustomPaint>(scene).painter! as BrandIntroPainter)
            .progress;
    expect(progress.value, 0);
    expect(scene, findsOneWidget);

    ready.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(progress.value, greaterThan(0));
    await tester.pumpAndSettle();
    expect(scene, findsNothing);
  });

  testWidgets('Replay works from DEV without reinstalling and can be skipped', (
    tester,
  ) async {
    await tester.pumpWidget(devBrandApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Panel de desarrollo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reproducir intro URBES'));
    await tester.pump();
    expect(scene, findsOneWidget);
    await tester.tapAt(tester.getCenter(scene));
    await tester.pump();
    expect(scene, findsNothing);
    expect(find.text('Panel de desarrollo'), findsWidgets);
  });

  testWidgets('A critical event removes the intro before showing emergency', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(devBrandApp(key: key));
    await tester.pump();
    expect(scene, findsOneWidget);
    final context = key.currentContext!;
    (context.read<EventRepository>() as MockEventRepository).triggerSos();
    await tester.pump();
    await tester.pump();
    expect(scene, findsNothing);
    expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Reduced motion bypasses scene and replay', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(devBrandApp());
    await tester.pumpAndSettle();
    expect(scene, findsNothing);
    await tester.tap(find.byTooltip('Panel de desarrollo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reproducir intro URBES'));
    await tester.pump();
    expect(scene, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enabling reduced motion during drawing closes the scene', (
    tester,
  ) async {
    await tester.pumpWidget(devBrandApp());
    await tester.pump();
    expect(scene, findsOneWidget);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(scene, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Backgrounding ends the scene and resume never restarts it', (
    tester,
  ) async {
    await tester.pumpWidget(devBrandApp());
    await tester.pump();
    expect(scene, findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(scene, findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(scene, findsNothing);
  });
}
