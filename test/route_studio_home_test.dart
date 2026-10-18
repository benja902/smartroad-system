import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/models/accident_severity.dart';
import 'package:smartroad/models/device_status.dart';
import 'package:smartroad/navigation/navigation_visual_preview.dart';
import 'package:smartroad/repositories/device_repository.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_data_seed.dart';
import 'package:smartroad/repositories/mock/mock_device_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/screens/home/home_visual_preview.dart';
import 'package:smartroad/screens/home/premium_home_content.dart';
import 'package:smartroad/widgets/attention_banner.dart';
import 'package:smartroad/state/event_provider.dart';

import 'home_visual_preview_test.dart'
    show app, chooseHome, reveal, presentation;

void main() {
  for (final size in [(320.0, 1.0), (390.0, 2.0), (484.0, 1.3)]) {
    testWidgets(
      'Studio vehicle asset decodes without cropping at ${size.$1} dp / ${size.$2} text',
      (tester) async {
        // Decode the image offline without flushing pending network font loads.
        // The same local font fixture is used by the existing visual exporter.
        final font = ByteData.sublistView(
          File('docs/ui_ux/premium_phase1/assets/Manrope-variable.ttf')
              .readAsBytesSync(),
        );
        const asset = 'docs/ui_ux/premium_phase1/home_review/auto.webp';
        final bytes = ByteData.sublistView(File(asset).readAsBytesSync());
        final names = [
          'Regular',
          'Medium',
          'SemiBold',
          'Bold',
          'ExtraBold',
        ].map((weight) => 'Manrope-$weight.ttf').toList();
        final messenger = tester.binding.defaultBinaryMessenger;
        final fetching = GoogleFonts.config.allowRuntimeFetching;
        GoogleFonts.config.allowRuntimeFetching = false;
        messenger.setMockMessageHandler('flutter/assets', (message) async {
          final key = const StringCodec().decodeMessage(message);
          if (key == 'AssetManifest.bin') {
            return const StandardMessageCodec().encodeMessage({
              for (final name in names)
                name: [
                  {'asset': name},
                ],
            });
          }
          if (key == asset) return bytes;
          return names.contains(key) ? font : null;
        });
        addTearDown(() {
          messenger.setMockMessageHandler('flutter/assets', null);
          GoogleFonts.config.allowRuntimeFetching = fetching;
        });
        tester.view.physicalSize = Size(size.$1, 1055);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          presentation(
            HomePreviewVariant.routeStudio,
            status: MockDataSeed.initialDeviceStatus,
            textScale: size.$2,
          ),
        );
        await tester.pumpAndSettle();
        final finder = find.byKey(const ValueKey('studio-vehicle-image'));
        final widget = tester.widget<Image>(finder);
        await tester.runAsync(
          () => precacheImage(widget.image, tester.element(finder)),
        );
        await tester.pumpAndSettle();
        expect(widget.fit, BoxFit.contain);
        expect(widget.color, isNull);
        expect(
          find.byKey(const ValueKey('studio-vehicle-fallback')),
          findsNothing,
        );
        expect(
          tester
              .widget<RawImage>(
                find.descendant(of: finder, matching: find.byType(RawImage)),
              )
              .image,
          isNotNull,
        );
        expect(find.text('SDA reportado conectado'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Bento diagnostics are opt-in through the existing DEV menu', (
    tester,
  ) async {
    await app(tester);
    await chooseHome(tester, HomePreviewVariant.routeStudio);
    expect(
      find.byKey(const ValueKey('studio-layout-diagnostics')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('dev-nav-variant-menu')));
    await tester.pumpAndSettle();
    final toggle = find.byWidgetPredicate(
      (widget) =>
          widget is CheckboxMenuButton &&
          widget.key == const ValueKey('dev-home-layout-diagnostics'),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.byKey(const ValueKey('studio-layout-diagnostics')),
    );
    expect(
      find.byKey(const ValueKey('studio-layout-diagnostics')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  for (final sample in [
    (412.0, 1.0, '342.0', '3 columnas'),
    // The test renderer uses Ahem; its wider glyphs need more room here.
    (412.0, 1.3, '342.0', 'vertical'),
    (484.0, 1.3, '414.0', '3 columnas'),
    (320.0, 1.0, '250.0', 'vertical'),
    (320.0, 2.0, '250.0', 'vertical'),
    (390.0, 2.0, '320.0', 'vertical'),
  ]) {
    testWidgets(
      'Bento diagnostic ${sample.$1} dp / ${sample.$2} text reports actual constraint and reason',
      (tester) async {
        tester.view.physicalSize = Size(sample.$1, 940);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          HomeVisualPreview(
            variant: HomePreviewVariant.routeStudio,
            layoutDiagnostics: true,
            child: presentation(
              HomePreviewVariant.routeStudio,
              status: MockDataSeed.initialDeviceStatus,
              textScale: sample.$2,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const ValueKey('studio-layout-diagnostics')),
        );
        final reading = tester
            .widget<SelectableText>(
              find.descendant(
                of: find.byKey(const ValueKey('studio-layout-diagnostics')),
                matching: find.byType(SelectableText),
              ),
            )
            .data!;
        expect(reading, contains('Ancho interior: ${sample.$3} dp'));
        expect(reading, contains('Distribución: ${sample.$4}'));
        expect(
          find.byKey(
            ValueKey(
              sample.$4 == '3 columnas'
                  ? 'studio-bento-columns'
                  : 'studio-bento-vertical',
            ),
          ),
          findsOneWidget,
        );
        expect(reading, isNot(contains('texto de 14 escala a más de 17')));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Design 1 is DEV-only, profile action signs out through existing session',
    (tester) async {
      await app(tester, dev: false);
      expect(
        tester
            .widget<PremiumHomeContent>(find.byType(PremiumHomeContent))
            .variant,
        HomePreviewVariant.guardianDeck,
      );
      expect(find.byKey(const ValueKey('studio-profile')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await app(tester);
      await chooseHome(tester, HomePreviewVariant.routeStudio);
      expect(find.byKey(const ValueKey('studio-hero')), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('premium-nav-item-$i')), findsOneWidget);
      }
      final profile = find.byKey(const ValueKey('studio-profile'));
      expect(tester.getSize(profile).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(profile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Omitir introducción'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Design 1 reacts to SDA, mobile and GNSS; preserves acknowledgement and critical priority',
    (tester) async {
      await app(tester);
      await chooseHome(tester, HomePreviewVariant.routeStudio);
      final context = tester.element(find.byType(PremiumHomeContent));
      final device = context.read<DeviceRepository>() as MockDeviceRepository;
      final events = context.read<EventRepository>() as MockEventRepository;
      device.setDeviceOffline(true);
      device.setCellularOffline(true);
      device.setGnssOffline(true);
      await tester.pumpAndSettle();
      expect(find.text('SDA reportado desconectado'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('studio-device')));
      expect(find.text('Sin registro reportado'), findsOneWidget);
      expect(find.text('Sin fix reportado'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('home-position')));
      expect(find.text('0.00000, 0.00000'), findsNothing);
      expect(find.text('Sin coordenadas para mostrar'), findsOneWidget);
      final incident = events.triggerCrash(severity: AccidentSeverity.moderado);
      await tester.pumpAndSettle();
      await reveal(tester, find.byType(AttentionBanner), delta: -180);
      expect(
        tester.getTopLeft(find.byType(AttentionBanner)).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('studio-hero'))).dy,
        ),
      );
      final acknowledge = find.widgetWithText(ElevatedButton, 'Ya lo vi');
      await tester.ensureVisible(acknowledge);
      await tester.tap(acknowledge);
      await tester.pumpAndSettle();
      expect(find.byType(AttentionBanner), findsNothing);
      expect(
        context
            .read<EventProvider>()
            .events
            .singleWhere((e) => e.dedupKey == incident.dedupKey)
            .acknowledged,
        isTrue,
      );
      events.triggerSos();
      await tester.pumpAndSettle();
      expect(find.byType(PremiumNavigationPreviewBar), findsNothing);
      expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Design 1 treats absent values, epoch and event error neutrally',
    (tester) async {
      await tester.pumpWidget(
        presentation(
          HomePreviewVariant.routeStudio,
          absentVehicle: true,
          eventError: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sin información del SDA'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('studio-device')));
      expect(find.text('Sin dato'), findsOneWidget);
      expect(find.text('Registro no informado'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('home-event-error')));
      expect(find.byKey(const ValueKey('home-event-error')), findsOneWidget);
      expect(find.text('Todo en orden'), findsNothing);
      expect(find.text('Ver mapa'), findsNothing);
      await tester.pumpWidget(
        presentation(
          HomePreviewVariant.routeStudio,
          status: DeviceStatus(
            deviceId: 'test-device',
            lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey('studio-hero')),
        delta: -180,
      );
      expect(find.text('Última comunicación no disponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Design 1 ${width.toInt()} dp / ${scale}x text: scroll, keyboard, reduced motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var opens = 0;
          await tester.pumpWidget(
            presentation(
              HomePreviewVariant.routeStudio,
              status: MockDataSeed.initialDeviceStatus,
              textScale: scale,
              reduced: true,
              onOpenAlerts: () => opens++,
            ),
          );
          await tester.pumpAndSettle();
          final tile = find.byType(ExpansionTile);
          await reveal(tester, tile);
          await tester.tap(tile);
          await tester.pumpAndSettle();
          expect(
            tester.widget<ExpansionTile>(tile).expansionAnimationStyle,
            AnimationStyle.noAnimation,
          );
          expect(find.text('Intensidad de señal'), findsOneWidget);
          final alerts = find.byKey(const ValueKey('home-open-alerts'));
          await reveal(tester, alerts);
          Focus.of(tester.element(find.text('Ver todas'))).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(opens, 1);
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
