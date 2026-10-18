import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroad/app.dart';
import 'package:smartroad/core/theme/app_typography.dart';
import 'package:smartroad/screens/dev/dev_navigation_review.dart';
import 'package:smartroad/screens/home/home_visual_preview.dart';

import 'home_visual_preview_test.dart' show chooseHome;
import 'test_helpers.dart';

/// Optional two-frame offline Flutter render, not another review application.
void main() {
  for (final width in [390, 320]) {
    testWidgets('Guardian mobile render $width', (tester) async {
      final font = ByteData.sublistView(
        File('docs/ui_ux/premium_phase1/assets/Manrope-variable.ttf')
            .readAsBytesSync(),
      );
      final names = [
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
      ].map((w) => 'Manrope-$w.ttf').toList();
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
        return names.contains(key) ? font : null;
      });
      addTearDown(() {
        messenger.setMockMessageHandler('flutter/assets', null);
        GoogleFonts.config.allowRuntimeFetching = fetching;
      });
      tester.view.physicalSize = Size(width.toDouble(), 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        for (final family in {
          'Manrope',
          'Roboto',
          AppTypography.displayLg.fontFamily!,
          AppTypography.bodyMd.fontFamily!,
          AppTypography.bodyLg.fontFamily!,
          AppTypography.labelSm.fontFamily!,
        }) {
          await (FontLoader(family)..addFont(Future.value(font))).load();
        }
        const sdk = String.fromEnvironment(
          'URBES_FLUTTER_SDK',
          defaultValue: 'C:/development/flutter',
        );
        final icons = await File(
          '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(ByteData.sublistView(icons)))).load();
      });
      const capture = ValueKey('guardian-mobile-capture');
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: mockAppProviders(
            child: UrbesApp(
              includeDevRoute: true,
              devBuilder: (context, child) =>
                  DevNavigationReview(child: child!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await chooseHome(tester, HomePreviewVariant.guardianDeck);
      await tester.tap(find.byKey(const ValueKey('dev-nav-variant-menu')));
      await tester.pumpAndSettle();
      final artwork = find.byKey(const ValueKey('dev-guardian-isometric'));
      await tester.ensureVisible(artwork);
      await tester.tap(artwork);
      await tester.pumpAndSettle();
      if (width == 320) {
        await tester.tap(find.byKey(const ValueKey('dev-nav-variant-menu')));
        await tester.pumpAndSettle();
        final header = find.byKey(const ValueKey('dev-guardian-header-menu'));
        await tester.ensureVisible(header);
        await tester.tap(header);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('dev-guardian-header-editorial')),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(capture),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final treatment = width == 390 ? 'signature' : 'editorial';
        await File(
          'docs/ui_ux/premium_phase1/home_review/guardian_header_$treatment.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }, skip: !const bool.fromEnvironment('URBES_EXPORT_GUARDIAN'));
  }
}
