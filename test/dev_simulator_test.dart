import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smartroad/app.dart';
import 'package:smartroad/main_dev.dart' as dev_entry;
import 'package:smartroad/repositories/auth_repository.dart';
import 'package:smartroad/repositories/device_repository.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_auth_repository.dart';
import 'package:smartroad/repositories/mock/mock_device_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/repositories/mock/mock_vehicle_repository.dart';
import 'package:smartroad/repositories/vehicle_repository.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('main_dev.dart injects every mock without Firebase initialization', (tester) async {
    dev_entry.main();
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(UrbesApp));
    expect(context.read<AuthRepository>(), isA<MockAuthRepository>());
    expect(context.read<VehicleRepository>(), isA<MockVehicleRepository>());
    expect(context.read<DeviceRepository>(), isA<MockDeviceRepository>());
    expect(context.read<EventRepository>(), isA<MockEventRepository>());
    expect(find.byTooltip('Panel de desarrollo'), findsOneWidget);
  });

  testWidgets('Production app (includeDevRoute: false) hides the /dev entry point', (tester) async {
    await tester.pumpWidget(mockAppProviders(child: const UrbesApp()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Panel de desarrollo'), findsNothing);
  });

  testWidgets('Dev app exposes the /dev panel and its toggles affect Home live', (tester) async {
    await tester.pumpWidget(mockAppProviders(child: const UrbesApp(includeDevRoute: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Panel de desarrollo'));
    await tester.pumpAndSettle();

    expect(find.text('Panel de desarrollo'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('Vuelco grave'), findsOneWidget);

    await tester.tap(find.text('Vuelco grave'));
    await tester.pumpAndSettle();

    // Triggering a grave rollover from /dev must force navigation to the
    // critical route immediately, same as if the hardware had reported it.
    expect(find.text('VOLCADURA DETECTADA'), findsOneWidget);
  });

  testWidgets('Production build never shows the "Volver a /dev" escape hatch, even during an emergency', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;
    repo.triggerCrash();
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsOneWidget);
    expect(find.text('Volver a /dev'), findsNothing);
  });

  testWidgets('Dev build: crash -> active emergency -> back to /dev -> cancel -> emergency auto-closes', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key, includeDevRoute: true)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    final event = repo.triggerCrash();
    await tester.pumpAndSettle();
    expect(find.text('CHOQUE SEVERO DETECTADO'), findsOneWidget);

    await tester.ensureVisible(find.text('Volver a /dev'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a /dev'));
    await tester.pumpAndSettle();

    // Still on /dev, not bounced back — the escape hatch works even while
    // the emergency remains unresolved.
    expect(find.text('Panel de desarrollo'), findsWidgets);
    expect(find.text('CHOQUE SEVERO DETECTADO'), findsNothing);

    repo.triggerCancel(event.seq);
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsNothing);
    expect(find.text('Panel de desarrollo'), findsWidgets);
  });

  testWidgets(
      'Dev build: after returning to /dev, a genuinely NEW crash still forces the emergency screen '
      '(the override only applies to the event you left, not forever)', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key, includeDevRoute: true)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerCrash();
    await tester.pumpAndSettle();
    expect(find.text('CHOQUE SEVERO DETECTADO'), findsOneWidget);

    await tester.ensureVisible(find.text('Volver a /dev'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a /dev'));
    await tester.pumpAndSettle();
    expect(find.text('Panel de desarrollo'), findsWidgets);

    // A second, distinct crash while sitting on /dev must still pop the
    // emergency screen back open — the escape hatch must not silently
    // suppress the redirect for every future event.
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choque grave'));
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsOneWidget);
  });
}
