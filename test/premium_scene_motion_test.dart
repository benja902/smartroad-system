import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_scene.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_scene_motion.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_vehicle.dart';

import 'brand_intro_test.dart' show devBrandApp;

Future<void> openBuild(WidgetTester tester, {Key? key}) async {
  await tester.pumpWidget(devBrandApp(key: key));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Panel de desarrollo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reproducir construcción por capas D'));
  await tester.pump();
  await tester.pump();
}

void main() {
  test(
    'All layer transforms and nested opacity follow actual JS reveal calls',
    () {
      final data = jsonDecode(
        File(
          'docs/ui_ux/premium_phase1/flutter_increment_1/scene_reference.json',
        ).readAsStringSync(),
      );
      for (final sample in data['samples']) {
        final ms = (sample['ms'] as num).toDouble();
        for (final entry
            in (sample['layers'] as Map<String, dynamic>).entries) {
          if (entry.key == 'object-tree-3') {
            continue; // T4 intentionally absent.
          }
          final expected = entry.value;
          if (entry.key == 'layer-vehicle') {
            expect(
              PremiumSceneMotion.vehicleOpacity(ms),
              closeTo(expected['opacity'], 1e-12),
            );
            continue;
          }
          final actual = PremiumSceneMotion.layer(entry.key, ms);
          expect(
            entry.key == 'layer-landscape'
                ? PremiumSceneMotion.landscapeOpacity(ms)
                : actual.opacity,
            closeTo(expected['opacity'], 1e-12),
            reason: '${entry.key} at $ms',
          );
          final values = RegExp(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?')
              .allMatches(expected['transform'])
              .map((m) => double.parse(m[0]!))
              .toList();
          expect(actual.dy, closeTo(values[1], 1e-12));
          expect(actual.pivot.dx, values[2]);
          expect(actual.pivot.dy, values[3]);
          expect(actual.scale, closeTo(values[4], 1e-12));
        }
      }
      expect(
        PremiumSceneMotion.layer('layer-ground', 0).opacity,
        greaterThan(0),
      );
      expect(PremiumSceneMotion.layer('object-tree-4', 490).opacity, 0);
      expect(PremiumSceneMotion.layer('object-tree-2', 955).opacity, 1);
    },
  );

  testWidgets(
    'Layer composition captures partial and complete construction without errors',
    (tester) async {
      final key = GlobalKey(), clock = ValueNotifier<double>(0);
      addTearDown(clock.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 620,
                height: 430,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: PremiumScenePainter(
                          portion: PremiumScenePortion.beforeVehicle,
                          motionProgress: clock,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: PremiumVehiclePainter(clock, reveal: true),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: PremiumScenePainter(
                          portion: PremiumScenePortion.afterVehicle,
                          motionProgress: clock,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      for (final ms in [0, 380, 720, 955, 2160]) {
        clock.value = ms / 2600;
        await tester.pump();
        final image = (await tester.runAsync(() => boundary.toImage()))!;
        if (const bool.fromEnvironment('URBES_EXPORT_LAYERS')) {
          final bytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          ))!;
          await tester.runAsync(
            () => File(
              'docs/ui_ux/premium_phase1/flutter_increment_1/layers_$ms.png',
            ).writeAsBytes(bytes.buffer.asUint8List()),
          );
        }
        image.dispose();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DEV shares one clock; layers stop repainting after 955ms, car continues',
    (tester) async {
      await openBuild(tester);
      var preview = tester.widget<PremiumScenePreview>(
        find.byType(PremiumScenePreview),
      );
      expect(preview.sceneProgress!.value, preview.vehicleProgress!.value);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(preview.sceneProgress!.value, 955 / 2600);
      final car = preview.vehicleProgress!.value;
      await tester.pump(const Duration(milliseconds: 400));
      expect(preview.vehicleProgress!.value, greaterThan(car));
      expect(preview.sceneProgress!.value, 955 / 2600);
      await tester.pump(const Duration(seconds: 2));
      expect(preview.vehicleProgress!.value, 1);
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reproducir recorrido del vehículo D'));
      await tester.pump();
      preview = tester.widget<PremiumScenePreview>(
        find.byType(PremiumScenePreview),
      );
      expect(preview.sceneProgress, isNull);
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Emergency interrupts layer build with original routing', (
    tester,
  ) async {
    final key = GlobalKey();
    await openBuild(tester, key: key);
    (key.currentContext!.read<EventRepository>() as MockEventRepository)
        .triggerSos();
    await tester.pump();
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
    expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Reduced motion bypasses or dismisses layer build', (
    tester,
  ) async {
    await openBuild(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
    await tester.tap(find.text('Reproducir construcción por capas D'));
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });

  testWidgets('Background cancels construction and resume does not restart', (
    tester,
  ) async {
    await openBuild(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });
}
