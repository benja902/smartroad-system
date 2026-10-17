import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/presentation/premium_scene/premium_scene.dart';
import 'package:smartroad/presentation/premium_scene/premium_vehicle.dart';

import 'brand_intro_test.dart' show devBrandApp;

Future<void> openMotion(WidgetTester tester, {Key? key}) async {
  await tester.pumpWidget(devBrandApp(key: key));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Panel de desarrollo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reproducir recorrido del vehículo D'));
  await tester.pump();
  await tester.pump();
}

void main() {
  test('Trajectory, facing, depth order and projected vertices match approved JS', () {
    final data = jsonDecode(
      File(
        'docs/ui_ux/premium_phase1/flutter_increment_1/vehicle_reference.json',
      ).readAsStringSync(),
    );
    expect(
      PremiumVehicleMotion.routeLength,
      closeTo(data['route_length'], 1e-9),
    );
    for (final sample in data['samples']) {
      final pose = PremiumVehicleMotion.atMilliseconds(
        (sample['ms'] as num).toDouble(),
      );
      for (final pair in [
        (pose.x, sample['pose']['x']),
        (pose.y, sample['pose']['y']),
        (pose.angle, sample['pose']['angle']),
      ]) {
        expect(pair.$1, closeTo(pair.$2, 1e-9));
      }
      final faces = PremiumVehiclePainter.faces(pose);
      expect(faces.length, 42);
      final expectedFaces = List<Map<String, dynamic>>.from(sample['faces']);
      expectedFaces.sort((a, b) {
        final d = ((a['depth'] as num) * 1e9).round().compareTo(
          ((b['depth'] as num) * 1e9).round(),
        );
        return d == 0 ? (a['id'] as int).compareTo(b['id'] as int) : d;
      });
      for (var i = 0; i < faces.length; i++) {
        final expected = expectedFaces[i], actual = faces[i];
        expect(
          actual.id,
          expected['id'],
          reason:
              'ms=${sample['ms']}, face=$i, depth=${actual.depth}, JS=${expected['depth']}',
        );
        expect(actual.visible, expected['visible']);
        expect(actual.depth, closeTo(expected['depth'], 1e-9));
        expect(actual.points.first.dx, closeTo(expected['first'][0], 1e-9));
        expect(actual.points.first.dy, closeTo(expected['first'][1], 1e-9));
      }
    }
  });

  test('1201 eased samples stay continuous and turn monotonically without angle jumps', () {
    var previous = PremiumVehicleMotion.at(0);
    for (var i = 1; i <= 1200; i++) {
      final p = PremiumVehicleMotion.at(PremiumVehicleMotion.ease(i / 1200));
      expect(p.angle, inInclusiveRange(-math.pi / 2, 1e-10));
      expect(p.angle, lessThanOrEqualTo(previous.angle + 1e-10));
      expect(
        (PremiumVehicleMotion.project(p.x, p.y) -
                PremiumVehicleMotion.project(previous.x, previous.y))
            .distance,
        lessThan(1),
      );
      expect((p.angle - previous.angle).abs(), lessThan(math.pi / 180));
      previous = p;
    }
    expect(PremiumVehicleMotion.atMilliseconds(600).x, 64);
    expect(PremiumVehicleMotion.atMilliseconds(2600).y, 70);
  });

  testWidgets(
    'Native isolated vehicle renders start, turn and end without exceptions',
    (tester) async {
      final key = GlobalKey(), progress = ValueNotifier<double>(0);
      addTearDown(progress.dispose);
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
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: PremiumVehiclePainter(progress),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: PremiumScenePainter(
                          portion: PremiumScenePortion.afterVehicle,
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
      for (final ms in [0, 1400, 2160, 2600]) {
        progress.value = ms / 2600;
        await tester.pump();
        final image = (await tester.runAsync(() => boundary.toImage()))!;
        expect(image.width, 620);
        if (const bool.fromEnvironment('URBES_EXPORT_VEHICLE')) {
          final bytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          ))!;
          await tester.runAsync(
            () => File(
              'docs/ui_ux/premium_phase1/flutter_increment_1/vehicle_$ms.png',
            ).writeAsBytes(bytes.buffer.asUint8List()),
          );
        }
        image.dispose();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DEV motion finishes at endpoint, stays visible, closes and preserves static mode',
    (tester) async {
      await openMotion(tester);
      expect(find.byType(PremiumScenePreview), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<PremiumVehiclePainter>()
          .single;
      expect(painter.progress.value, 1);
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver escena premium D (estática)'));
      await tester.pump();
      expect(
        tester
            .widget<PremiumScenePreview>(find.byType(PremiumScenePreview))
            .vehicleProgress,
        isNull,
      );
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Emergency interrupts vehicle and keeps existing emergency navigation',
    (tester) async {
      final key = GlobalKey();
      await openMotion(tester, key: key);
      (key.currentContext!.read<EventRepository>() as MockEventRepository)
          .triggerSos();
      await tester.pump();
      await tester.pump();
      expect(find.byType(PremiumScenePreview), findsNothing);
      expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Reduced motion bypasses vehicle review', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openMotion(tester);
    expect(find.byType(PremiumScenePreview), findsNothing);
  });

  testWidgets('Enabling reduced motion stops visible vehicle', (tester) async {
    await openMotion(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });

  testWidgets('Background cancels vehicle without reopening on resume', (
    tester,
  ) async {
    await openMotion(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });
}
