import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../presentation/premium_scene/premium_scene.dart';

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
    final progress = timeline?.progress ?? PremiumLoginTimeline.completed;
    final theme = original.copyWith(
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
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: dy + 340 * fit),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    dx + 24 * fit,
                                    0,
                                    dx + 24 * fit,
                                    24,
                                  ),
                                  child: ValueListenableBuilder<double>(
                                    valueListenable: progress,
                                    builder: (context, value, child) =>
                                        value * 2600 >= 4090
                                        ? child!
                                        : const SizedBox.shrink(),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Builder defers Form mounting until the handoff.
                                        Builder(
                                          builder: (_) => formBuilder(fit),
                                        ),
                                        if (timeline?.footer != null) ...[
                                          const SizedBox(height: 16),
                                          timeline!.footer!,
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
