import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../presentation/premium_scene/premium_scene.dart';
import '../../presentation/premium_scene/premium_closure_motion.dart';
import 'login_visual_style.dart';

/// Presentation inputs only. The DEV host owns playback; the ordinary route
/// defaults to the completed frame. No repository, auth or router in this scope.
class PremiumLoginTimeline extends InheritedWidget {
  const PremiumLoginTimeline({
    super.key,
    required super.child,
    this.progress = completed,
    this.sceneProgress = builtScene,
    this.vehicleProgress = parkedVehicle,
    this.headerAction,
    this.footer,
  });

  static const completed = AlwaysStoppedAnimation<double>(4440 / 2600);
  static const builtScene = AlwaysStoppedAnimation<double>(955 / 2600);
  static const parkedVehicle = AlwaysStoppedAnimation<double>(1);
  final ValueListenable<double> progress, sceneProgress, vehicleProgress;
  final Widget? headerAction, footer;

  static PremiumLoginTimeline? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PremiumLoginTimeline>();

  @override
  bool updateShouldNotify(PremiumLoginTimeline oldWidget) =>
      progress != oldWidget.progress ||
      sceneProgress != oldWidget.sceneProgress ||
      vehicleProgress != oldWidget.vehicleProgress ||
      headerAction != oldWidget.headerAction ||
      footer != oldWidget.footer;
}

/// Single premium surface for the real LoginScreen, routed or under DEV review.
class PremiumLoginPresentation extends StatelessWidget {
  const PremiumLoginPresentation({
    super.key,
    required this.formBuilder,
    this.timeline,
  });
  final Widget Function(double fit) formBuilder;
  final PremiumLoginTimeline? timeline;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final original = Theme.of(context);
    final visualScope = LoginVisualScope.maybeOf(context);
    final variant = LoginVisualScope.variantOf(context);
    final signature = variant == LoginVisualVariant.signature;
    final progress = timeline?.progress ?? PremiumLoginTimeline.completed;
    final currentTheme = original.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: original.colorScheme.copyWith(
        primary: const Color(0xFF031B3B),
      ),
      inputDecorationTheme: original.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFC5C6CE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF031B3B), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF031B3B),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
    final theme = variant.experimental
        ? LoginVisualStyle.theme(
            original,
            variant,
            reducedMotion: MediaQuery.disableAnimationsOf(context),
          )
        : currentTheme;
    return Theme(
      data: theme,
      child: Scaffold(
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fullHeight = constraints.maxHeight + keyboardInset;
              final fit = math.min(
                constraints.maxWidth / 390,
                fullHeight / 844,
              );
              final dx = (constraints.maxWidth - 390 * fit) / 2;
              final dy = (fullHeight - 844 * fit) / 2;
              final formInset = variant.experimental
                  ? math.max(0.0, (constraints.maxWidth - 440) / 2) +
                        (constraints.maxWidth <= 360 ? 20 : 24)
                  : dx + 24 * fit;
              // D's final illustration stays at (14, 71), scale .6. The panel
              // begins below its visible ground; 312 + 28 keeps title y=340.
              final panelTop = dy + (signature ? 312 : 340) * fit;
              final formContent = Padding(
                padding: EdgeInsets.fromLTRB(
                  formInset,
                  signature ? 28 * fit : 0,
                  formInset,
                  24,
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, value, child) =>
                      value * 2600 >= 4090 ? child! : const SizedBox.shrink(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Form mounting still occurs only at D's handoff.
                      Builder(builder: (_) => formBuilder(fit)),
                      if (timeline?.footer != null) ...[
                        const SizedBox(height: 16),
                        timeline!.footer!,
                      ],
                    ],
                  ),
                ),
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      key: const ValueKey('premium-login-scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: fullHeight),
                        child: Stack(
                          children: [
                            if (variant.experimental)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ExcludeSemantics(
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: progress,
                                      child: ColoredBox(
                                        color: signature
                                            ? LoginVisualStyle.heroSurface
                                            : Colors.white,
                                      ),
                                      builder: (context, value, child) =>
                                          Opacity(
                                            opacity: _handoffOpacity(value),
                                            child: child,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: dx,
                              top: dy,
                              width: 390 * fit,
                              height: 844 * fit,
                              child: IgnorePointer(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: PremiumClosureArtboard(
                                    progress: progress,
                                    sceneProgress:
                                        timeline?.sceneProgress ??
                                        PremiumLoginTimeline.builtScene,
                                    vehicleProgress:
                                        timeline?.vehicleProgress ??
                                        PremiumLoginTimeline.parkedVehicle,
                                    showDestinationLabel: false,
                                    finalSceneZoom: 1.0,
                                    backgroundColor: variant.experimental
                                        ? Colors.transparent
                                        : const Color(0xFFF8F9FA),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: panelTop),
                                if (signature)
                                  _SignatureLoginPanel(
                                    progress: progress,
                                    minHeight: math.max(
                                      0,
                                      fullHeight - panelTop,
                                    ),
                                    child: formContent,
                                  )
                                else
                                  formContent,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (timeline?.headerAction != null)
                    Positioned(
                      right: 8,
                      top: 0,
                      child: timeline!.headerAction!,
                    ),
                  if (visualScope?.reviewAction != null)
                    Positioned(
                      right: 8,
                      top: timeline?.headerAction != null ? 48 : 8,
                      child: ValueListenableBuilder<double>(
                        valueListenable: progress,
                        child: visualScope!.reviewAction,
                        builder: (context, value, child) => value * 2600 >= 4440
                            ? child!
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

double _handoffOpacity(double progress) => PremiumClosureMotion.easeOut(
  PremiumClosureMotion.phase(progress * 2600, 4090, 4330),
);

/// One lower surface, not an extra card or form. Only its background fades;
/// title/fields/button keep their existing entrances and interaction semantics.
class _SignatureLoginPanel extends StatelessWidget {
  const _SignatureLoginPanel({
    required this.progress,
    required this.minHeight,
    required this.child,
  });
  final ValueListenable<double> progress;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('signature-login-panel'),
    width: double.infinity,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: progress,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A031B3B),
                        blurRadius: 16,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                ),
                builder: (context, value, child) => Opacity(
                  key: const ValueKey('signature-panel-opacity'),
                  opacity: _handoffOpacity(value),
                  child: child,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}
