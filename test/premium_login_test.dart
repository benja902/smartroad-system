import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/core/theme/app_theme.dart';
import 'package:smartroad/core/theme/app_typography.dart';
import 'package:smartroad/models/user_model.dart';
import 'package:smartroad/repositories/auth_repository.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/screens/dev/premium_scene/premium_scene.dart';
import 'package:smartroad/state/session_provider.dart';
import 'package:smartroad/widgets/screen_entrance.dart';

import 'brand_intro_test.dart' show devBrandApp;

Future<void> openLogin(WidgetTester tester, {Key? key}) async {
  await tester.pumpWidget(devBrandApp(key: key));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Panel de desarrollo'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Reproducir Splash → Login real DEV'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reproducir Splash → Login real DEV'));
  await tester.pump();
  await tester.pump();
}

Future<void> skip(WidgetTester tester) async {
  await tester.tap(find.text('Omitir introducción'));
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(TextFormField).first);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextFormField).first,
    'pilot@example.invalid',
  );
  await tester.ensureVisible(find.byType(TextFormField).last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).last, 'demo-only');
}

class ControlledAuth implements AuthRepository {
  final pending = Completer<UserModel>();
  int calls = 0;
  @override
  Stream<UserModel?> authStateChanges() => Stream.value(null);
  @override
  Future<UserModel> signIn(String email, String password) {
    calls++;
    return pending.future;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets(
    'Real form mounts at 4090ms; sections follow D without ScreenEntrance replay',
    (tester) async {
      const export = bool.fromEnvironment('URBES_EXPORT_LOGIN');
      if (export) {
        // QA-only bundle: satisfy google_fonts with the existing local font.
        // No application asset manifest or runtime configuration is changed.
        final localFont = ByteData.sublistView(
          File('docs/ui_ux/premium_phase1/assets/Manrope-variable.ttf')
              .readAsBytesSync(),
        );
        final names = [
          'Regular',
          'Medium',
          'SemiBold',
          'Bold',
          'ExtraBold',
        ].map((weight) => 'Manrope-$weight.ttf').toList();
        final previousFetching = GoogleFonts.config.allowRuntimeFetching;
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
          return names.contains(key) ? localFont : null;
        });
        addTearDown(() {
          messenger.setMockMessageHandler('flutter/assets', null);
          GoogleFonts.config.allowRuntimeFetching = previousFetching;
        });
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      await openLogin(tester);
      if (export) {
        final families = {
          AppTypography.displayLg.fontFamily!,
          AppTypography.bodyMd.fontFamily!,
          AppTypography.bodyLg.fontFamily!,
          AppTypography.labelSm.fontFamily!,
          'Roboto',
        };
        await tester.runAsync(() async {
          final bytes = await File(
            'docs/ui_ux/premium_phase1/assets/Manrope-variable.ttf',
          ).readAsBytes();
          for (final family in families) {
            final loader = FontLoader(family)
              ..addFont(Future.value(ByteData.sublistView(bytes)));
            await loader.load();
          }
        });
      }
      expect(find.byType(LoginScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 4080));
      expect(find.byType(LoginScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(ScreenEntrance), findsNothing);
      final sections = tester
          .widgetList<DevLoginEntrance>(find.byType(DevLoginEntrance))
          .toList();
      expect(sections.map((s) => s.start), orderedEquals([4090, 4130, 4170]));
      expect(
        sections.every((s) => identical(s.progress, sections.first.progress)),
        true,
      );
      await tester.pump(const Duration(milliseconds: 120));
      // D at 4210ms: independently calculated cubic-out samples.
      for (var i = 0; i < sections.length; i++) {
        final opacity = tester.widget<Opacity>(
          find
              .descendant(
                of: find.byWidget(sections[i]),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(opacity.opacity, closeTo([0.875, 19 / 27, 91 / 216][i], 1e-9));
      }
      await tester.pump(const Duration(milliseconds: 230));
      expect(sections.first.progress.value, 4440 / 2600);
      final sceneScale = tester.widget<Transform>(
        find.byKey(const ValueKey('premium-closure-scene-scale')),
      );
      expect(sceneScale.transform.entry(0, 0), closeTo(.6, 1e-12));
      expect(sceneScale.transform.entry(1, 1), closeTo(.6, 1e-12));
      final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(
        paints.where((w) => w.painter is PremiumClosureBrandPainter),
        hasLength(1),
      );
      expect(paints.where((w) => w.painter is PremiumBeaconPainter), isEmpty);
      expect(
        find.text('URBES'),
        findsNothing,
      ); // one vector lockup, no legacy header.
      if (export) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('premium-login-capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'docs/ui_ux/premium_phase1/flutter_increment_1/login_flutter_4440.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('Cerrar DEV'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Omit intro reveals usable real validators and mock submit leaves outer session/router intact',
    (tester) async {
      final key = GlobalKey();
      await openLogin(tester, key: key);
      final outer = key.currentContext!.read<SessionProvider>(),
          before = key.currentContext!.read<SessionProvider>().user;
      await skip(tester);
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('Ingresa tu correo'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      final inputs = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(inputs.first.autofillHints, contains(AutofillHints.email));
      expect(inputs.last.autofillHints, contains(AutofillHints.password));
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        true,
      );
      final local = tester
          .element(find.byType(LoginScreen))
          .read<SessionProvider>();
      expect(identical(local, outer), false);
      await fill(tester);
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(local.user?.email, 'pilot@example.invalid');
      expect(outer.user, same(before));
      expect(
        find.text(
          'Acceso mock verificado. La sesión de la app no se ha cambiado.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cerrar DEV'));
      await tester.pumpAndSettle();
      expect(find.text('Panel de desarrollo'), findsWidgets);
    },
  );
  for (final error in [
    const AccountNotProvisionedException(),
    FirebaseAuthException(code: 'invalid-credential'),
  ]) {
    testWidgets(
      'Real submit preserves busy state, keyboard submit and ${error.runtimeType} mapping',
      (tester) async {
        final auth = ControlledAuth(),
            session = SessionProvider(ControlledAuth());
        session.dispose(); // only the instance below owns auth in this test.
        final actual = SessionProvider(auth),
            clock = ValueNotifier<double>(4440 / 2600);
        addTearDown(actual.dispose);
        addTearDown(clock.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider<SessionProvider>.value(
            value: actual,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: LoginScreen(
                    presentationBuilder: (context, parts) =>
                        DevPremiumLoginForm(
                          parts: parts,
                          progress: clock,
                          translationScale: 1,
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
        await fill(tester);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(auth.calls, 1);
        expect(find.text('Ingresando…'), findsOneWidget);
        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(button.onPressed, isNull);
        auth.pending.completeError(error);
        await tester.pumpAndSettle();
        expect(
          find.text(
            error is AccountNotProvisionedException
                ? 'Esta cuenta aún no está provisionada.'
                : 'Correo o contraseña incorrectos.',
          ),
          findsOneWidget,
        );
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Keyboard and 200 percent text scroll without moving the vector handoff',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);
      await openLogin(tester);
      await skip(tester);
      final artBefore = tester.getTopLeft(find.byType(PremiumClosureArtboard));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(PremiumClosureArtboard)), artBefore);
      await fill(tester);
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cerrar DEV'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Reduced motion immediately presents real form and does not replay when disabled',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await openLogin(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      final preview = tester.widget<DevPremiumLoginPreview>(
        find.byType(DevPremiumLoginPreview),
      );
      expect(preview.progress.value, 4440 / 2600);
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      expect(preview.progress.value, 4440 / 2600);
      await tester.tap(find.text('Cerrar DEV'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('Enabling reduced motion during intro hands off immediately', (
    tester,
  ) async {
    await openLogin(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Cerrar DEV'), findsOneWidget);
    await tester.tap(find.text('Cerrar DEV'));
    await tester.pumpAndSettle();
  });
  testWidgets('Critical event interrupts focused real form immediately', (
    tester,
  ) async {
    final key = GlobalKey();
    await openLogin(tester, key: key);
    await skip(tester);
    await fill(tester);
    (key.currentContext!.read<EventRepository>() as MockEventRepository)
        .triggerSos();
    await tester.pump();
    await tester.pump();
    expect(find.byType(DevPremiumLoginPreview), findsNothing);
    expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
    await tester.pumpAndSettle();
  });
  testWidgets(
    'Background dismisses review, disposes form and does not reopen',
    (tester) async {
      await openLogin(tester);
      await skip(tester);
      await fill(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(DevPremiumLoginPreview), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );
}
