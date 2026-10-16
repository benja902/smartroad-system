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
import 'package:smartroad/screens/dev/brand_intro/dev_brand_intro.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_closure_motion.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_scene.dart';
import 'package:smartroad/state/session_provider.dart';

import 'brand_intro_test.dart' show devBrandApp;

Future<void> openClosure(WidgetTester tester, {Key? key}) async {
  await tester.pumpWidget(devBrandApp(key: key));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Panel de desarrollo'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Reproducir cierre de marca D'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reproducir cierre de marca D'));
  await tester.pump();
  await tester.pump();
}

List<double> numbers(String s) =>
    RegExp(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?')
        .allMatches(s)
        .map((m) => double.parse(m[0]!))
        .toList();
void main() {
  test('Closure matches original D transforms including double-smoothed lockup Y', () {
    final data = jsonDecode(
      File(
        'docs/ui_ux/premium_phase1/flutter_increment_1/closure_reference.json',
      ).readAsStringSync(),
    );
    for (final sample in data['samples']) {
      final s = PremiumClosureMotion.atMilliseconds(
        (sample['ms'] as num).toDouble(),
      );
      final symbol = numbers(sample['symbol']['transform']),
          lockup = numbers(sample['lockup']['transform']),
          scene = numbers(sample['scene']['transform']);
      expect(s.symbol.dx, closeTo(symbol[0], 1e-10));
      expect(s.symbol.dy, closeTo(symbol[1], 1e-10));
      expect(s.symbolScale, closeTo(symbol[2], 1e-12));
      expect(s.lockup.dx, closeTo(lockup[0], 1e-10));
      expect(s.lockup.dy, closeTo(lockup[1], 1e-10));
      expect(s.lockupScale, closeTo(lockup[2], 1e-12));
      expect(s.sceneY, closeTo(scene[1], 1e-10));
      expect(
        s.shadowOpacity,
        closeTo(sample['shadow']['style']['opacity'], 1e-12),
      );
      expect(s.wordOpacity, closeTo(sample['word']['style']['opacity'], 1e-12));
    }
    expect(PremiumClosureMotion.atMilliseconds(3360).symbol, Offset.zero);
    expect(
      PremiumClosureMotion.atMilliseconds(3540).lockup,
      const Offset(131, 633),
    );
    final end = PremiumClosureMotion.atMilliseconds(4440);
    expect(end.lockup, const Offset(42, 47));
    expect(end.lockupScale, .625);
    expect(end.sceneY, 71);
  });
  test('One continuous symbol/wordmark across reaction, docking and delivery seams', () {
    var previous = PremiumClosureMotion.atMilliseconds(0);
    for (var ms = 1; ms <= 4440; ms++) {
      final s = PremiumClosureMotion.atMilliseconds(ms.toDouble());
      expect((s.symbolOnPhone - previous.symbolOnPhone).distance, lessThan(3));
      expect(
        (s.wordBaselineOnPhone - previous.wordBaselineOnPhone).distance,
        lessThan(3),
      );
      expect((s.symbolScale - previous.symbolScale).abs(), lessThan(.002));
      if (ms > 2200) expect(s.wordOpacity, 1);
      previous = s;
    }
    for (final seam in [2680, 3360, 3540, 4090]) {
      final a = PremiumClosureMotion.atMilliseconds(seam - .001),
          b = PremiumClosureMotion.atMilliseconds(seam + .001);
      expect((a.symbolOnPhone - b.symbolOnPhone).distance, lessThan(.001));
      expect(
        (a.wordBaselineOnPhone - b.wordBaselineOnPhone).distance,
        lessThan(.001),
      );
    }
  });
  testWidgets('Phone artboard captures flight, dock, delivery and final header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey(),
        clock = ValueNotifier<double>(0),
        scene = ValueNotifier<double>(0),
        vehicle = ValueNotifier<double>(0);
    addTearDown(clock.dispose);
    addTearDown(scene.dispose);
    addTearDown(vehicle.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: PremiumClosureArtboard(
              showDestinationLabel: false,
              progress: clock,
              sceneProgress: scene,
              vehicleProgress: vehicle,
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    for (final ms in [3100, 3450, 3800, 4440]) {
      clock.value = ms / 2600;
      scene.value = 955 / 2600;
      vehicle.value = math.min(clock.value, 1);
      await tester.pump();
      final image = (await tester.runAsync(() => boundary.toImage()))!;
      expect(image.width, 390);
      expect(image.height, 844);
      if (const bool.fromEnvironment('URBES_EXPORT_CLOSURE')) {
        final bytes = (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        ))!;
        await tester.runAsync(
          () => File(
            'docs/ui_ux/premium_phase1/flutter_increment_1/closure_flutter_$ms.png',
          ).writeAsBytes(bytes.buffer.asUint8List()),
        );
      }
      image.dispose();
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Closure uses mock session unchanged and returns to same DEV route on skip',
    (tester) async {
      final key = GlobalKey();
      await openClosure(tester, key: key);
      final session = key.currentContext!.read<SessionProvider>(),
          user = session.user;
      final p = tester.widget<PremiumClosurePreview>(
        find.byType(PremiumClosurePreview),
      );
      await tester.pump(const Duration(milliseconds: 3600));
      expect(p.vehicleProgress.value, 1);
      expect(p.sceneProgress.value, 955 / 2600);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(p.progress.value, 4440 / 2600);
      expect(session.user, same(user));
      expect(find.byType(Form), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      await tester.tapAt(tester.getCenter(find.byType(PremiumClosurePreview)));
      await tester.pumpAndSettle();
      expect(find.text('Panel de desarrollo'), findsWidgets);
      expect(session.user, same(user));
      await tester.ensureVisible(find.text('Reproducir baliza flotante D'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reproducir baliza flotante D'));
      await tester.pump();
      expect(find.byType(PremiumScenePreview), findsOneWidget);
      expect(find.byType(PremiumClosurePreview), findsNothing);
      await tester.tapAt(tester.getCenter(find.byType(PremiumScenePreview)));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('Critical event interrupts delivery immediately', (tester) async {
    final key = GlobalKey();
    await openClosure(tester, key: key);
    await tester.pump(const Duration(milliseconds: 3800));
    (key.currentContext!.read<EventRepository>() as MockEventRepository)
        .triggerSos();
    await tester.pump();
    await tester.pump();
    expect(find.byType(PremiumClosurePreview), findsNothing);
    expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
    await tester.pumpAndSettle();
  });
  testWidgets('Reduced motion dismisses and bypasses closure', (tester) async {
    await openClosure(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.byType(PremiumClosurePreview), findsNothing);
    await tester.tap(find.text('Reproducir cierre de marca D'));
    await tester.pump();
    expect(find.byType(PremiumClosurePreview), findsNothing);
  });
  testWidgets('Background cancels closure without resume replay', (
    tester,
  ) async {
    await openClosure(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(PremiumClosurePreview), findsNothing);
  });
  testWidgets(
    'Small screen and 200 percent text retain one semantic skip action',
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
        context.read<DevBrandIntroController>().showClosure();
        await tester.pump();
        expect(
          find.bySemanticsLabel('Cierre de marca URBES. Toca para cerrar'),
          findsOneWidget,
        );
        await tester.pump(const Duration(milliseconds: 4600));
        expect(tester.takeException(), isNull);
        await tester.tapAt(
          tester.getCenter(find.byType(PremiumClosurePreview)),
        );
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    },
  );
}
