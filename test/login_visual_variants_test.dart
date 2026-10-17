import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/core/theme/app_colors.dart';
import 'package:smartroad/core/theme/app_theme.dart';
import 'package:smartroad/core/theme/app_typography.dart';
import 'package:smartroad/main_dev.dart' as dev_entry;
import 'package:smartroad/presentation/premium_scene/premium_scene.dart';
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/screens/auth/login_visual_style.dart';
import 'package:smartroad/screens/auth/premium_login_presentation.dart';
import 'package:smartroad/state/session_provider.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/dev/premium_login_preview.dart';

import 'premium_login_route_test.dart' show openRouted, submit;
import 'premium_login_test.dart' show ControlledAuth, fill;

Future<void> choose(WidgetTester tester, LoginVisualVariant variant) async {
  await tester.tap(find.byKey(const ValueKey('dev-login-variant-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, variant.label));
  await tester.pumpAndSettle();
}

Future<void> surface(
  WidgetTester tester,
  LoginVisualVariant variant, {
  ControlledAuth? auth,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SessionProvider(auth ?? ControlledAuth()),
      child: RepaintBoundary(
        key: const ValueKey('login-visual-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: LoginVisualScope(variant: variant, child: const LoginScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Actual DEV entrypoint starts with Signature v2 and only its existing D host',
    (tester) async {
      await dev_entry.main();
      await tester.pump();
      await tester.pump();
      final context = tester.element(find.byType(LoginScreen));
      expect(LoginVisualScope.variantOf(context), LoginVisualVariant.signature);
      expect(
        find.byKey(const ValueKey('signature-login-panel')),
        findsOneWidget,
      );
      expect(PremiumLoginTimeline.maybeOf(context)!.progress.value, 0);
      expect(context.read<SessionProvider>().isSignedIn, false);
      expect(find.byType(Form), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Panel preview shares DEV variant selection and emergency still preempts it',
    (tester) async {
      final key = await openRouted(tester, visualReview: true);
      await tester.tap(find.text('Omitir introducción'));
      await tester.pumpAndSettle();
      await choose(tester, LoginVisualVariant.signature);
      await submit(tester);
      await tester.tap(find.byTooltip('Panel de desarrollo'));
      await tester.pumpAndSettle();
      final replay = find.text('Reproducir Splash → Login real DEV');
      await tester.ensureVisible(replay);
      await tester.tap(replay);
      await tester.pump();
      await tester.pump();
      expect(find.byType(DevPremiumLoginPreview), findsOneWidget);
      expect(find.byType(Form), findsNothing);
      await tester.tap(find.text('Omitir introducción'));
      await tester.pumpAndSettle();
      expect(
        LoginVisualScope.variantOf(tester.element(find.byType(LoginScreen))),
        LoginVisualVariant.signature,
      );
      await choose(tester, LoginVisualVariant.refined);
      expect(
        LoginVisualScope.variantOf(tester.element(find.byType(LoginScreen))),
        LoginVisualVariant.refined,
      );
      expect(find.byType(Form), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dev-login-variant-menu')));
      await tester.pumpAndSettle();
      (key.currentContext!.read<EventRepository>() as MockEventRepository)
          .triggerSos();
      await tester.pumpAndSettle();
      expect(find.byType(DevPremiumLoginPreview), findsNothing);
      expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
      expect(find.byType(MenuItemButton), findsNothing);
      expect(key.currentContext!.read<SessionProvider>().isSignedIn, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'DEV selector preserves one form, typed data and the completed D clock',
    (tester) async {
      await openRouted(tester, visualReview: true);
      expect(
        find.byKey(const ValueKey('dev-login-variant-menu')),
        findsNothing,
      );
      await tester.tap(find.text('Omitir introducción'));
      await tester.pumpAndSettle();
      await fill(tester);
      final formState = tester.state(find.byType(Form));
      final clock = PremiumLoginTimeline.maybeOf(
        tester.element(find.byType(LoginScreen)),
      )!.progress;
      for (final variant in [
        LoginVisualVariant.refined,
        LoginVisualVariant.signature,
        LoginVisualVariant.current,
      ]) {
        await choose(tester, variant);
        expect(
          LoginVisualScope.variantOf(tester.element(find.byType(LoginScreen))),
          variant,
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .decoration!
              .labelText,
          variant.experimental ? 'Correo electrónico' : 'CORREO',
        );
        expect(
          find.byIcon(Icons.mail_outline_rounded),
          variant.experimental ? findsOneWidget : findsNothing,
        );
        expect(
          find.byTooltip('Mostrar contraseña'),
          variant.experimental ? findsOneWidget : findsNothing,
        );
        expect(tester.state(find.byType(Form)), same(formState));
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .first
              .controller
              .text,
          'pilot@example.invalid',
        );
        expect(find.byType(Form), findsOneWidget);
        expect(clock.value, 4440 / 2600);
        expect(find.text('Omitir introducción'), findsNothing);
        expect(
          tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .where((w) => w.painter is PremiumClosureBrandPainter),
          hasLength(1),
        );
      }
      expect(find.byTooltip('Mostrar contraseña'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Signature v2 integrates one panel without moving the D artboard at handoff',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clock = ValueNotifier<double>(4089 / 2600);
      addTearDown(clock.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SessionProvider(ControlledAuth()),
          child: MaterialApp(
            theme: AppTheme.light,
            home: LoginVisualScope(
              variant: LoginVisualVariant.signature,
              child: PremiumLoginTimeline(
                progress: clock,
                child: const LoginScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final panel = find.byKey(const ValueKey('signature-login-panel'));
      final art = find.byType(PremiumClosureArtboard);
      final before = tester.getRect(art);
      expect(tester.getRect(panel).top, 312);
      expect(tester.getRect(panel).width, 390);
      expect(tester.getRect(panel).bottom, 844);
      expect(find.byType(Form), findsNothing);
      for (final sample in <(double, double)>[
        (4089, 0),
        (4090, 0),
        (4210, .875),
        (4330, 1),
        (4440, 1),
      ]) {
        clock.value = sample.$1 / 2600;
        await tester.pump();
        expect(tester.getRect(art), before);
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('signature-panel-opacity')),
              )
              .opacity,
          closeTo(sample.$2, 1e-10),
        );
        expect(
          find.byType(Form),
          sample.$1 < 4090 ? findsNothing : findsOneWidget,
        );
        final transform = tester.widget<Transform>(
          find.byKey(const ValueKey('premium-closure-scene-scale')),
        );
        expect(transform.transform.entry(0, 0), .6);
        expect(transform.transform.entry(1, 1), .6);
        expect(
          tester.widget<PremiumClosureArtboard>(art).progress,
          same(clock),
        );
      }
      expect(tester.getTopLeft(find.text('Bienvenido.')).dy, 340);
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((w) => w.painter is PremiumClosureBrandPainter),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Outside DEV defaults to static Signature v2 with no selector or automatic D',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SessionProvider(ControlledAuth()),
          child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dev-login-variant-menu')),
        findsNothing,
      );
      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('signature-login-panel')),
        findsOneWidget,
      );
      expect(
        LoginVisualScope.variantOf(tester.element(find.byType(LoginScreen))),
        LoginVisualVariant.signature,
      );
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        true,
      );
      final art = tester.widget<PremiumClosureArtboard>(
        find.byType(PremiumClosureArtboard),
      );
      expect(art.backgroundColor, Colors.transparent);
      expect(art.progress, same(PremiumLoginTimeline.completed));
      expect(find.text('Omitir introducción'), findsNothing);
      expect(art.finalSceneZoom, 1);
      expect(find.text('Bienvenido.'), findsOneWidget);
    },
  );

  for (final variant in [
    LoginVisualVariant.refined,
    LoginVisualVariant.signature,
  ]) {
    testWidgets(
      '${variant.name}: visibility, validation, loading and real mapped error',
      (tester) async {
        final auth = ControlledAuth();
        await surface(tester, variant, auth: auth);
        await tester.ensureVisible(find.text('Iniciar sesión'));
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
        expect(find.text('Ingresa tu correo'), findsOneWidget);
        expect(find.text('Ingresa tu contraseña'), findsOneWidget);
        expect(auth.calls, 0);
        await fill(tester);
        final field = find.byType(TextFormField).last;
        await tester.ensureVisible(field);
        await tester.tap(find.byTooltip('Mostrar contraseña'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).last)
              .obscureText,
          false,
        );
        final eye = find.byTooltip('Ocultar contraseña');
        expect(tester.getSize(eye).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(eye).height, greaterThanOrEqualTo(48));
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .last
              .controller
              .text,
          'demo-only',
        );
        await tester.tap(eye);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).last)
              .obscureText,
          true,
        );
        // Editing already focused the field; revealing/hiding preserves that focus.
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .last
              .focusNode
              .hasFocus,
          true,
        );
        final theme = Theme.of(tester.element(field));
        final border =
            theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
        expect(border.borderSide.width, 2);
        expect(
          border.borderSide.color,
          variant == LoginVisualVariant.signature
              ? LoginVisualStyle.teal
              : LoginVisualStyle.navy,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField).last).autofillHints,
          [AutofillHints.password],
        );
        await tester.ensureVisible(find.text('Iniciar sesión'));
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pump();
        expect(auth.calls, 1);
        expect(find.text('Ingresando…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
        auth.pending.completeError(
          FirebaseAuthException(code: 'invalid-credential'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      },
    );

    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${variant.name}: ${width.toInt()}dp / ${scale * 100}% / keyboard',
          (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            addTearDown(tester.view.resetViewInsets);
            await surface(tester, variant);
            final artBefore = tester.getTopLeft(
              find.byType(PremiumClosureArtboard),
            );
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pumpAndSettle();
            expect(
              tester.getTopLeft(find.byType(PremiumClosureArtboard)),
              artBefore,
            );
            await fill(tester);
            await tester.ensureVisible(find.text('Iniciar sesión'));
            await tester.pumpAndSettle();
            final button = tester.getRect(find.byType(ElevatedButton));
            expect(button.left, greaterThanOrEqualTo(0));
            expect(button.right, lessThanOrEqualTo(width));
            expect(button.height, greaterThanOrEqualTo(60));
            expect(button.bottom, lessThanOrEqualTo(844 - 260 + .1));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('Reduced motion keeps review usable and busy indicator static', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openRouted(tester, visualReview: true);
    expect(find.byType(Form), findsOneWidget);
    await choose(tester, LoginVisualVariant.signature);
    expect(find.text('Omitir introducción'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    final auth = ControlledAuth();
    await surface(tester, LoginVisualVariant.signature, auth: auth);
    await fill(tester);
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      .75,
    );
    auth.pending.completeError(
      FirebaseAuthException(code: 'invalid-credential'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('Candidate roles keep readable controls and text on white', () {
    double contrast(Color c) => 1.05 / (c.computeLuminance() + .05);
    for (final color in [
      LoginVisualStyle.navy,
      LoginVisualStyle.teal,
      LoginVisualStyle.error,
    ]) {
      expect(contrast(color), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(AppColors.outline), greaterThanOrEqualTo(3));
  });

  const export = bool.fromEnvironment('URBES_EXPORT_LOGIN_VARIANTS');
  testWidgets('Own visual evidence: current, Refined and Signature', (
    tester,
  ) async {
    final materialIcons = await rootBundle.load(
      'fonts/MaterialIcons-Regular.otf',
    );
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
    GoogleFonts.config.allowRuntimeFetching = false;
    final messenger = tester.binding.defaultBinaryMessenger;
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
      GoogleFonts.config.allowRuntimeFetching = true;
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // QA-only local font; no new runtime asset or external fetch.
    await tester.runAsync(() async {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(materialIcons))).load();
      for (final family in {
        AppTypography.displayLg.fontFamily!,
        AppTypography.bodyMd.fontFamily!,
        AppTypography.bodyLg.fontFamily!,
        AppTypography.labelSm.fontFamily!,
        'Roboto',
      }) {
        await (FontLoader(family)..addFont(Future.value(font))).load();
      }
    });
    for (final variant in LoginVisualVariant.values) {
      await surface(tester, variant);
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('login-visual-capture')),
        );
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          'docs/ui_ux/premium_phase1/login_signature_review/${variant.name}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  }, skip: !export);
}
