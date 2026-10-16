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
import 'package:smartroad/screens/dev/premium_scene/premium_beacon_motion.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_scene.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_scene_motion.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_vehicle.dart';

import 'brand_intro_test.dart' show devBrandApp;

Future<void> openBeacon(WidgetTester tester, {Key? key}) async {
  await tester.pumpWidget(devBrandApp(key: key));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Panel de desarrollo'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Reproducir baliza flotante D'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reproducir baliza flotante D'));
  await tester.pump();
  await tester.pump();
}

void main() {
  test(
    'Beacon matches actual D symbol/shadow/wave transforms in 16 JS samples',
    () {
      final data = jsonDecode(
        File(
          'docs/ui_ux/premium_phase1/flutter_increment_1/beacon_reference.json',
        ).readAsStringSync(),
      );
      expect(PremiumBeaconMotion.encounterMilliseconds, data['encounter_ms']);
      expect(PremiumBeaconMotion.endMilliseconds, 2680);
      for (final sample in data['samples']) {
        final s = PremiumBeaconMotion.atMilliseconds(
          (sample['ms'] as num).toDouble(),
        );
        final values = RegExp(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?')
            .allMatches(sample['symbol']['transform'])
            .map((m) => double.parse(m[0]!))
            .toList();
        final origin = Offset(
          14 + .6 * PremiumBeaconMotion.anchor.dx,
          270 + .6 * PremiumBeaconMotion.anchor.dy,
        );
        expect(s.offset.dx, closeTo(values[0] + 131 - origin.dx, 1e-10));
        expect(s.offset.dy, closeTo(values[1] + 633 - origin.dy, 1e-10));
        expect(.3 * s.scale, closeTo(values[2], 1e-12));
        expect(s.opacity, closeTo(sample['symbol']['style']['opacity'], 1e-12));
        expect(
          s.shadowOpacity,
          closeTo(sample['shadow']['style']['opacity'], 1e-12),
        );
        expect(s.shadowRx, closeTo(sample['shadow']['rx'], 1e-12));
        expect(s.shadowRy, closeTo(sample['shadow']['ry'], 1e-12));
        expect(s.waveRx, closeTo(sample['wave']['rx'], 1e-12));
        expect(s.waveRy, closeTo(sample['wave']['ry'], 1e-12));
        expect(s.waveOpacity, closeTo(sample['waveOpacity'], 1e-12));
        expect(
          sample['wave']['cx'],
          closeTo(14 + .6 * PremiumBeaconMotion.foot.dx, 1e-12),
        );
        expect(
          sample['wave']['cy'],
          closeTo(270 + .6 * PremiumBeaconMotion.foot.dy, 1e-12),
        );
      }
    },
  );

  test('Contact follows actual nose distance; hover settles before a single reaction', () {
    final cue = PremiumBeaconMotion.encounterMilliseconds.toDouble();
    expect(
      (PremiumBeaconMotion.nose(cue) - PremiumBeaconMotion.foot).distance,
      lessThanOrEqualTo(16),
    );
    expect(
      (PremiumBeaconMotion.nose(cue - 1) - PremiumBeaconMotion.foot).distance,
      greaterThan(16),
    );
    expect(PremiumBeaconMotion.atMilliseconds(1560).offset.dy, -2);
    for (final ms in [2160, 2250, 2399]) {
      final s = PremiumBeaconMotion.atMilliseconds(ms.toDouble());
      expect(s.offset, Offset.zero);
      expect(s.waveOpacity, 0);
      expect(s.scale, 1);
    }
    final peak = PremiumBeaconMotion.atMilliseconds(cue + 140);
    expect(peak.offset.distance, closeTo(3, 1e-12));
    expect(peak.scale, 1.035);
    expect(peak.waveOpacity, .65);
    final end = PremiumBeaconMotion.atMilliseconds(2680);
    expect(end.offset.distance, lessThan(1e-12));
    expect(end.waveOpacity, lessThan(1e-12));
    var previous = PremiumBeaconMotion.atMilliseconds(0);
    for (var ms = 1; ms <= 2680; ms++) {
      final s = PremiumBeaconMotion.atMilliseconds(ms.toDouble());
      expect((s.offset - previous.offset).distance, lessThan(.04));
      expect((s.opacity - previous.opacity).abs(), lessThan(.013));
      expect((s.scale - previous.scale).abs(), lessThan(.001));
      expect(s.waveOpacity, inInclusiveRange(0, .65));
      previous = s;
    }
    expect(PremiumBeaconMotion.direction.distance, closeTo(1, 1e-12));
    expect(
      PremiumBeaconMotion.direction.dx.isFinite &&
          PremiumBeaconMotion.direction.dy.isFinite,
      true,
    );
  });

  testWidgets(
    'Native frames show entry, hover, stability and contact without duplicated static logo',
    (tester) async {
      final key = GlobalKey(),
          clock = ValueNotifier<double>(0),
          scene = ValueNotifier<double>(0);
      addTearDown(clock.dispose);
      addTearDown(scene.dispose);
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
                          motionProgress: scene,
                          hideBeacon: true,
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
                          motionProgress: scene,
                          hideBeacon: true,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(painter: PremiumBeaconPainter(clock)),
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
      for (final ms in [0, 840, 1560, 2160, 2540, 2680]) {
        clock.value = ms / 2600;
        scene.value =
            math.min(ms, PremiumSceneMotion.completeMilliseconds) / 2600;
        await tester.pump();
        final image = (await tester.runAsync(() => boundary.toImage()))!;
        if (const bool.fromEnvironment('URBES_EXPORT_BEACON')) {
          final bytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          ))!;
          await tester.runAsync(
            () => File(
              'docs/ui_ux/premium_phase1/flutter_increment_1/beacon_$ms.png',
            ).writeAsBytes(bytes.buffer.asUint8List()),
          );
        }
        image.dispose();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DEV keeps shared timeline past car end through reaction and preserves earlier mode',
    (tester) async {
      await openBeacon(tester);
      final p = tester.widget<PremiumScenePreview>(
        find.byType(PremiumScenePreview),
      );
      expect(identical(p.vehicleProgress, p.beaconProgress), true);
      await tester.pump(const Duration(milliseconds: 2620));
      expect(p.vehicleProgress!.value, greaterThan(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(p.beaconProgress!.value, 2680 / 2600);
      expect(p.sceneProgress!.value, 955 / 2600);
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Reproducir construcción por capas D'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reproducir construcción por capas D'));
      await tester.pump();
      expect(
        tester
            .widget<PremiumScenePreview>(find.byType(PremiumScenePreview))
            .beaconProgress,
        isNull,
      );
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Emergency cancels beacon and retains existing route', (
    tester,
  ) async {
    final key = GlobalKey();
    await openBeacon(tester, key: key);
    (key.currentContext!.read<EventRepository>() as MockEventRepository)
        .triggerSos();
    await tester.pump();
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
    expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
    await tester.pumpAndSettle();
  });
  testWidgets('Reduced motion dismisses and bypasses beacon mode', (
    tester,
  ) async {
    await openBeacon(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
    await tester.tap(find.text('Reproducir baliza flotante D'));
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });
  testWidgets('Background closes beacon and resume does not reopen', (
    tester,
  ) async {
    await openBeacon(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(PremiumScenePreview), findsNothing);
  });
}
