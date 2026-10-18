import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/app.dart';
import 'package:smartroad/core/theme/app_theme.dart';
import 'package:smartroad/models/accident_severity.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/models/device_status.dart';
import 'package:smartroad/navigation/navigation_visual_preview.dart';
import 'package:smartroad/repositories/device_repository.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_data_seed.dart';
import 'package:smartroad/repositories/mock/mock_device_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/dev/dev_navigation_review.dart';
import 'package:smartroad/screens/alerts/alerts_screen.dart';
import 'package:smartroad/screens/home/home_visual_preview.dart';
import 'package:smartroad/screens/home/premium_home_content.dart';
import 'package:smartroad/state/event_provider.dart';
import 'package:smartroad/state/app_providers.dart';
import 'package:smartroad/widgets/attention_banner.dart';
import 'package:smartroad/screens/home/widgets/recent_alerts_preview.dart';

import 'test_helpers.dart';

// Test-only repository fault: uses the existing stream error contract.
// No scenario/control or error state is added to the DEV application.
class _ReadFailure extends MockEventRepository {
  @override
  Stream<List<AccidentEvent>> watchEvents(
    String userId, {
    String? vehicleId,
  }) async* {
    yield* Stream<List<AccidentEvent>>.error(
      StateError('Synthetic read failure'),
    );
  }
}

Future<void> reveal(
  WidgetTester tester,
  Finder target, {
  double delta = 180,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
}

Future<void> chooseHome(WidgetTester tester, HomePreviewVariant variant) async {
  await tester.tap(find.byKey(const ValueKey('dev-nav-variant-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('dev-home-${variant.name}')));
  await tester.pumpAndSettle();
}

Future<GlobalKey> app(WidgetTester tester, {bool dev = true}) async {
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

Widget presentation(
  HomePreviewVariant variant, {
  DeviceStatus? status,
  bool absentVehicle = false,
  bool eventError = false,
  double textScale = 1,
  bool reduced = false,
  VoidCallback? onOpenAlerts,
  GuardianArtwork guardianArtwork = GuardianArtwork.lineArt,
}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduced,
    ),
    child: PremiumHomeContent(
      variant: variant,
      guardianArtwork: guardianArtwork,
      userName: 'Persona de prueba',
      vehicle: absentVehicle ? null : MockDataSeed.vehicle,
      status: status,
      events: const [],
      eventError: eventError,
      attention: null,
      onOpenAlerts: onOpenAlerts ?? () {},
    ),
  ),
);

void main() {
  testWidgets(
    'Guardian impact icon does not imply resolution; acknowledgement uses visibility',
    (tester) async {
      final repo = MockEventRepository();
      final event = repo.triggerCrash(severity: AccidentSeverity.leve);
      Future<void> showEvents() async {
        final events = await repo.watchEvents(MockDataSeed.userId).first;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecentAlertsPreview(
                events: events,
                guardian: true,
                editorial: true,
                neutralEmpty: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await showEvents();
      expect(find.byIcon(Icons.car_crash_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      await repo.acknowledge(event.dedupKey, userId: MockDataSeed.userId);
      await showEvents();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    },
  );
  testWidgets(
    'Guardian switches only artwork, preserving data, official brand and visible connectivity',
    (tester) async {
      await app(tester);
      await chooseHome(tester, HomePreviewVariant.guardianDeck);
      final provider = tester
          .element(find.byType(PremiumHomeContent))
          .read<EventProvider>();
      expect(
        find.byKey(const ValueKey('guardian-official-brand')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guardian-art-lineArt')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('dev-nav-variant-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dev-guardian-isometric')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('guardian-art-isometric')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('guardian-art-lineArt')), findsNothing);
      expect(
        tester.element(find.byType(PremiumHomeContent)).read<EventProvider>(),
        same(provider),
      );
      await reveal(tester, find.text('Conectividad reportada'));
      expect(find.text('Red móvil'), findsOneWidget);
      expect(find.text('GNSS'), findsOneWidget);
      expect(find.text('LTE'), findsOneWidget);
      expect(find.text('Fix reportado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'DEV starts with current Home; A/B select without changing branches or nav',
    (tester) async {
      await app(tester);
      expect(find.byType(PremiumHomeContent), findsNothing);
      await chooseHome(tester, HomePreviewVariant.vehicleFocus);
      expect(find.byKey(const ValueKey('home-vehicle-hero')), findsOneWidget);
      final context = tester.element(find.byType(PremiumHomeContent));
      final events = context.read<EventProvider>();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -160));
      await tester.pumpAndSettle();
      final offset = scroll.position.pixels;
      await chooseHome(tester, HomePreviewVariant.contextualFocus);
      expect(
        find.byKey(const ValueKey('home-vehicle-compact')),
        findsOneWidget,
      );
      expect(
        tester.element(find.byType(PremiumHomeContent)).read<EventProvider>(),
        same(events),
      );
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable).first),
        same(scroll),
      );
      expect(scroll.position.pixels, closeTo(offset, .01));
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-2')));
      await tester.pumpAndSettle();
      expect(find.text('Próximamente'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('premium-nav-item-0')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-vehicle-compact')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PremiumNavigationPreviewBar>(
              find.byType(PremiumNavigationPreviewBar),
            )
            .variant,
        NavigationPreviewVariant.pillActive,
      );
      await chooseHome(tester, HomePreviewVariant.current);
      expect(find.byType(PremiumHomeContent), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('production ignores a supplied experimental Home scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      mockAppProviders(
        child: HomeVisualPreview(
          variant: HomePreviewVariant.vehicleFocus,
          child: const UrbesApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PremiumHomeContent), findsNothing);
    expect(
      find.text('Tu sistema URBES está funcionando correctamente'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dev-home-vehicleFocus')), findsNothing);
  });

  for (final variant in [
    HomePreviewVariant.vehicleFocus,
    HomePreviewVariant.contextualFocus,
    HomePreviewVariant.guardianDeck,
    HomePreviewVariant.signalFlow,
  ]) {
    testWidgets(
      '${variant.name}: EventProvider stream error reaches the shared presentation',
      (tester) async {
        final baseline = mockAppProviders(child: const SizedBox.shrink());
        await tester.pumpWidget(
          AppProviders(
            authRepository: baseline.authRepository,
            deviceRepository: baseline.deviceRepository,
            vehicleRepository: baseline.vehicleRepository,
            eventRepository: _ReadFailure(),
            child: UrbesApp(
              includeDevRoute: true,
              devBuilder: (context, child) =>
                  DevNavigationReview(child: child!),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await chooseHome(tester, variant);
        final context = tester.element(find.byType(PremiumHomeContent));
        expect(context.read<EventProvider>().error, isA<StateError>());
        await reveal(tester, find.byKey(const ValueKey('home-event-error')));
        expect(
          find.textContaining('Los registros mostrados pueden ser anteriores.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${variant.name}: real mock stream updates offline/GNSS, acknowledgement and emergency',
      (tester) async {
        await app(tester);
        await chooseHome(tester, variant);
        var context = tester.element(find.byType(PremiumHomeContent));
        final device = context.read<DeviceRepository>() as MockDeviceRepository;
        final repo = context.read<EventRepository>() as MockEventRepository;
        await reveal(tester, find.byKey(const ValueKey('home-availability')));
        expect(find.text('SDA reportado conectado'), findsOneWidget);
        device.setDeviceOffline(true);
        device.setGnssOffline(true);
        await tester.pumpAndSettle();
        expect(find.text('SDA reportado desconectado'), findsOneWidget);
        await reveal(tester, find.byKey(const ValueKey('home-position')));
        expect(find.text('Sin fix GNSS en el dato recibido'), findsOneWidget);
        expect(find.text('0.00000, 0.00000'), findsNothing);
        final incident = repo.triggerCrash(severity: AccidentSeverity.moderado);
        await tester.pumpAndSettle();
        await reveal(tester, find.byType(AttentionBanner), delta: -180);
        expect(find.byType(AttentionBanner), findsOneWidget);
        expect(
          tester
              .widget<AttentionBanner>(find.byType(AttentionBanner))
              .animateIcon,
          isFalse,
        );
        final acknowledge = find.widgetWithText(ElevatedButton, 'Ya lo vi');
        await tester.ensureVisible(acknowledge);
        await tester.tap(acknowledge);
        await tester.pumpAndSettle();
        expect(find.byType(AttentionBanner), findsNothing);
        context = tester.element(find.byType(PremiumHomeContent));
        expect(
          context
              .read<EventProvider>()
              .events
              .singleWhere((e) => e.dedupKey == incident.dedupKey)
              .acknowledged,
          isTrue,
        );
        final alerts = find.byKey(const ValueKey('home-open-alerts'));
        await reveal(tester, alerts);
        await tester.tap(alerts);
        await tester.pumpAndSettle();
        expect(find.byType(AlertsScreen), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('premium-nav-item-0')));
        await tester.pumpAndSettle();
        repo.triggerSos();
        await tester.pumpAndSettle();
        expect(find.byType(PremiumNavigationPreviewBar), findsNothing);
        expect(find.byType(PremiumHomeContent), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${variant.name}: nulls, epoch, event error are neutral, no fake actions',
      (tester) async {
        await tester.pumpWidget(
          presentation(variant, absentVehicle: true, eventError: true),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Información del vehículo no disponible'),
          findsOneWidget,
        );
        expect(find.text('Sin información del SDA'), findsOneWidget);
        expect(find.text('Última comunicación no disponible'), findsOneWidget);
        expect(find.text('Sin datos de ubicación'), findsOneWidget);
        await reveal(tester, find.byKey(const ValueKey('home-event-error')));
        expect(find.byKey(const ValueKey('home-event-error')), findsOneWidget);
        expect(find.text('Todo en orden'), findsNothing);
        expect(find.text('Ver mapa'), findsNothing);
        expect(find.text('Gestionar'), findsNothing);
        await tester.pumpWidget(
          presentation(
            variant,
            status: DeviceStatus(
              deviceId: 'test-device',
              lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const ValueKey('home-availability')),
          delta: -180,
        );
        expect(find.text('Última comunicación no disponible'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    for (final width in [320.0, 360.0, 390.0]) {
      for (final artwork
          in variant == HomePreviewVariant.guardianDeck
              ? GuardianArtwork.values
              : [GuardianArtwork.lineArt]) {
        testWidgets(
          '${variant.name}/${artwork.name}: ${width.toInt()} dp, 200% text, reduced motion, connectivity and action',
          (tester) async {
            tester.view.physicalSize = Size(width, 640);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var opens = 0;
            await tester.pumpWidget(
              presentation(
                variant,
                guardianArtwork: artwork,
                status: MockDataSeed.initialDeviceStatus,
                textScale: 2,
                reduced: true,
                onOpenAlerts: () => opens++,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.binding.hasScheduledFrame, isFalse);
            final tile = find.byType(ExpansionTile);
            await reveal(tester, tile);
            await tester.tap(tile);
            await tester.pumpAndSettle();
            expect(
              find.text(
                variant == HomePreviewVariant.guardianDeck
                    ? 'Voltaje de batería'
                    : 'Tecnología de red',
              ),
              findsOneWidget,
            );
            expect(find.text('LTE'), findsOneWidget);
            expect(
              tester.widget<ExpansionTile>(tile).expansionAnimationStyle,
              AnimationStyle.noAnimation,
            );
            final action = find.byKey(const ValueKey('home-open-alerts'));
            await reveal(tester, action);
            expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
            Focus.of(tester.element(find.text('Consultar alertas')))
                .requestFocus();
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(opens, 1);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
