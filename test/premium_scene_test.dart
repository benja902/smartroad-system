import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/dev/brand_intro/dev_brand_intro.dart';
import 'package:smartroad/presentation/premium_scene/premium_scene.dart';

import 'brand_intro_test.dart' show devBrandApp, scene;

const previewLabel = 'Ver escena premium D (estática)';

Future<void> openPreview(WidgetTester tester, {Key? key}) async {
  await tester.pumpWidget(devBrandApp(key: key));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Panel de desarrollo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(previewLabel));
  await tester.pump();
}

void main() {
  testWidgets('Native vectors paint at source resolution, without animation', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 620,
              height: 430,
              child: CustomPaint(painter: PremiumScenePainter()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final first = (await tester.runAsync(() => boundary.toImage()))!;
    final before = (await tester.runAsync(
      () => first.toByteData(format: ui.ImageByteFormat.png),
    ))!;
    await tester.pump(const Duration(seconds: 10));
    final second = (await tester.runAsync(() => boundary.toImage()))!;
    final after = (await tester.runAsync(
      () => second.toByteData(format: ui.ImageByteFormat.png),
    ))!;
    expect(first.width, 620);
    expect(first.height, 430);
    expect(
      before.buffer.asUint8List(),
      orderedEquals(after.buffer.asUint8List()),
    );
    if (const bool.fromEnvironment('URBES_EXPORT_SCENE')) {
      await tester.runAsync(
        () => File(
          'docs/ui_ux/premium_phase1/flutter_increment_1/flutter_scene.png',
        ).writeAsBytes(before.buffer.asUint8List()),
      );
    }
    first.dispose();
    second.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Manual static preview has no timeout, skips and preserves original intro',
    (tester) async {
      await openPreview(tester);
      expect(find.byType(PremiumScenePreview), findsOneWidget);
      expect(scene, findsNothing);
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(PremiumScenePreview), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumScenePreview), findsNothing);
      expect(find.text('Panel de desarrollo'), findsWidgets);
      await tester.tap(find.text('Reproducir intro URBES'));
      await tester.pump();
      expect(scene, findsOneWidget);
      expect(find.byType(PremiumScenePreview), findsNothing);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Critical event immediately closes static inspection', (
    tester,
  ) async {
    final key = GlobalKey();
    await openPreview(tester, key: key);
    (key.currentContext!.read<EventRepository>() as MockEventRepository)
        .triggerSos();
    await tester.pump();
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
    expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Reduced motion bypasses manual decorative inspection', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openPreview(tester);
    expect(find.byType(PremiumScenePreview), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enabling reduced motion dismisses visible static inspection', (
    tester,
  ) async {
    await openPreview(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });

  testWidgets('Background dismisses and resume never reopens inspection', (
    tester,
  ) async {
    await openPreview(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });

  testWidgets(
    'Small screen and 200 percent text remain usable with one skip semantic action',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(devBrandApp());
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(DevBrandIntroHost));
        context.read<DevBrandIntroController>().showPremiumScene();
        await tester.pump();
        expect(find.byType(PremiumScenePreview), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Escena estática URBES Premium D. Toca para cerrar',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
