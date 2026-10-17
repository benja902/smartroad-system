import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../state/event_provider.dart';
import '../../../state/session_provider.dart';
import '../../auth/premium_login_presentation.dart';
import '../../auth/login_visual_style.dart';
import '../dev_login_variant_menu.dart';
import '../premium_login_preview.dart';
import '../../../presentation/premium_scene/premium_scene.dart';
import '../../../presentation/premium_scene/premium_vehicle.dart';
import '../../../presentation/premium_scene/premium_scene_motion.dart';
import '../../../presentation/premium_scene/premium_beacon_motion.dart';
import '../../../presentation/premium_scene/premium_closure_motion.dart';

/// Exists only in main_dev.dart. The simulator requests a new presentation
/// without changing the router, session, or any repository.
class DevBrandIntroController extends ChangeNotifier {
  int _revision = 0;
  int get revision => _revision;
  bool _premiumScene = false;
  bool get isPremiumScene => _premiumScene;
  bool _vehicleMotion = false;
  bool get isVehicleMotion => _vehicleMotion;
  bool _sceneBuild = false;
  bool get isSceneBuild => _sceneBuild;
  bool _beacon = false;
  bool get isBeacon => _beacon;
  bool _closure = false;
  bool get isClosure => _closure;
  bool _login = false;
  bool get isLogin => _login;

  void replay() {
    _login = false;
    _closure = false;
    _beacon = false;
    _sceneBuild = false;
    _vehicleMotion = false;
    _premiumScene = false;
    _revision++;
    notifyListeners();
  }

  void showPremiumScene() {
    _login = false;
    _closure = false;
    _beacon = false;
    _sceneBuild = false;
    _vehicleMotion = false;
    _premiumScene = true;
    _revision++;
    notifyListeners();
  }

  void showVehicleMotion() {
    _login = false;
    _closure = false;
    _beacon = false;
    _sceneBuild = false;
    _premiumScene = true;
    _vehicleMotion = true;
    _revision++;
    notifyListeners();
  }

  void showSceneBuild({
    bool beacon = false,
    bool closure = false,
    bool login = false,
  }) {
    _login = login;
    _closure = closure;
    _beacon = beacon;
    _premiumScene = true;
    _vehicleMotion = true;
    _sceneBuild = true;
    _revision++;
    notifyListeners();
  }

  void showBeacon() => showSceneBuild(beacon: true);
  void showClosure() => showSceneBuild(beacon: true, closure: true);
  void showLogin() => showSceneBuild(beacon: true, closure: true, login: true);
}

/// Placed above the router by the DEV MaterialApp builder. The router builds
/// and reacts to provider changes underneath while this finite scene runs.
class DevBrandIntroHost extends StatefulWidget {
  const DevBrandIntroHost({
    super.key,
    required this.child,
    this.firstFrameReady,
    this.premiumLoginOnStartup = false,
    this.enableLoginVisualReview = false,
  });

  static const duration = Duration(milliseconds: 1900);
  final Widget child;
  final bool premiumLoginOnStartup;
  final bool enableLoginVisualReview;

  /// Overrides the engine signal in widget tests, which have no raster thread.
  final Future<void>? firstFrameReady;

  @override
  State<DevBrandIntroHost> createState() => _DevBrandIntroHostState();
}

class _DevBrandIntroHostState extends State<DevBrandIntroHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // A cold-start frame can take much longer than the motion itself. Advance
  // only by the time we could plausibly show in one frame, so a startup stall
  // cannot skip straight from the road to the final shield.
  static const _maximumFrameStep = Duration(milliseconds: 40);
  late final Ticker _ticker = createTicker(_onFrame);
  final ValueNotifier<double> _progress = ValueNotifier(0);
  final ValueNotifier<double> _sceneProgress = ValueNotifier(0);
  final ValueNotifier<double> _vehicleProgress = ValueNotifier(0);
  Duration? _previousFrameElapsed;
  Duration? _motionStart;
  DevBrandIntroController? _trigger;
  EventProvider? _events;
  SessionProvider? _session;
  bool _routeLogin = false;
  LoginVisualVariant _loginVariant = LoginVisualVariant.defaultVariant;
  int _shownRevision = -1;
  bool _visible = false;
  bool _showPremiumScene = false;
  bool _vehicleMotion = false;
  bool _sceneBuild = false;
  bool _beacon = false;
  bool _closure = false;
  bool _login = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_trigger == null) {
      _trigger = context.read<DevBrandIntroController>();
      _events = context.read<EventProvider>();
      _session = context.read<SessionProvider>();
      _trigger!.addListener(_onReplay);
      _events!.addListener(_onEventsChanged);
      _session!.addListener(_onSessionChanged);
      WidgetsBinding.instance.addObserver(this);
      if (widget.premiumLoginOnStartup && !_session!.isSignedIn) {
        _startRouteLogin(initial: true);
      } else {
        _onReplay(initial: true);
      }
    } else if (MediaQuery.disableAnimationsOf(context)) {
      if (_login || _routeLogin) {
        _skipLoginIntro();
      } else {
        _finish();
      }
    }
  }

  void _onSessionChanged() {
    // Session changes may finish startup decoration, never request a replay.
    if (_session!.isSignedIn && _routeLogin) {
      _ticker.stop();
      _routeLogin = false;
      if (mounted) setState(() {});
    }
  }

  void _startRouteLogin({bool initial = false}) {
    _ticker.stop();
    _routeLogin = true;
    _visible = false;
    _login = false;
    _vehicleMotion = true;
    _sceneBuild = true;
    _beacon = true;
    _closure = true;
    _shownRevision = _trigger!.revision;
    _previousFrameElapsed = null;
    _motionStart = null;
    _progress.value = 0;
    _sceneProgress.value = 0;
    _vehicleProgress.value = 0;
    if (MediaQuery.disableAnimationsOf(context) ||
        _events!.criticalEvent != null) {
      _skipLoginIntro();
    } else {
      _startWhenFirstFrameIsReady(_shownRevision);
    }
    if (mounted && !initial) setState(() {});
  }

  void _onReplay({bool initial = false}) {
    final revision = _trigger!.revision;
    if (_shownRevision == revision) return;
    _shownRevision = revision;
    _showPremiumScene = _trigger!.isPremiumScene;
    _vehicleMotion = _trigger!.isVehicleMotion;
    _sceneBuild = _trigger!.isSceneBuild;
    _beacon = _trigger!.isBeacon;
    _closure = _trigger!.isClosure;
    _login = _trigger!.isLogin;
    if (_events!.criticalEvent != null ||
        (MediaQuery.disableAnimationsOf(context) && !_login)) {
      _finish();
      return;
    }
    _visible = true;
    _ticker.stop();
    _previousFrameElapsed = null;
    _motionStart = null;
    _progress.value = 0;
    _sceneProgress.value = 0;
    _vehicleProgress.value = 0;
    if (_login && MediaQuery.disableAnimationsOf(context)) {
      _skipLoginIntro();
    } else if (!_showPremiumScene || _vehicleMotion) {
      _startWhenFirstFrameIsReady(revision);
    }
    if (mounted && !initial) setState(() {});
  }

  void _startWhenFirstFrameIsReady(int revision) {
    final binding = WidgetsBinding.instance;
    if (widget.firstFrameReady == null && binding.firstFrameRasterized) {
      _ticker.start();
      return;
    }
    // Keep the native-matching road still until the first Flutter frame has
    // actually been rasterized. Startup work must not consume the timeline.
    (widget.firstFrameReady ?? binding.waitUntilFirstFrameRasterized).then((_) {
      if (!mounted ||
          (!_visible && !_routeLogin) ||
          _shownRevision != revision) {
        return;
      }
      _ticker.start();
    });
  }

  void _onEventsChanged() {
    if (_events!.criticalEvent != null) _finish();
  }

  void _onFrame(Duration elapsed) {
    final previous = _previousFrameElapsed;
    _previousFrameElapsed = elapsed;
    if (previous == null) {
      _motionStart = elapsed;
      return;
    }
    if (_vehicleMotion) {
      final end = _closure
          ? PremiumClosureMotion.durationMilliseconds / 2600
          : _beacon
          ? PremiumBeaconMotion.endMilliseconds / 2600
          : 1.0;
      _progress.value = math.min(
        end,
        (elapsed - _motionStart!).inMicroseconds /
            PremiumVehicleMotion.duration.inMicroseconds,
      );
      if (_sceneBuild) {
        _sceneProgress.value = math.min(
          _progress.value,
          PremiumSceneMotion.completeMilliseconds / 2600,
        );
      }
      if (_closure) _vehicleProgress.value = math.min(_progress.value, 1);
      if (_progress.value >= end) _ticker.stop();
      return;
    }
    final frameElapsed = elapsed - previous;
    final boundedElapsed = frameElapsed > _maximumFrameStep
        ? _maximumFrameStep
        : frameElapsed;
    _progress.value = math.min(
      1,
      _progress.value +
          boundedElapsed.inMicroseconds /
              DevBrandIntroHost.duration.inMicroseconds,
    );
    if (_progress.value >= 1) _finish();
  }

  void _finish() {
    if (_routeLogin) {
      _skipLoginIntro();
      return;
    }
    if (!_visible) return;
    _ticker.stop();
    if (_login) FocusManager.instance.primaryFocus?.unfocus();
    _visible = false;
    if (mounted) setState(() {});
  }

  void _skipLoginIntro() {
    if (!_routeLogin && (!_visible || !_login)) return;
    if (!_routeLogin && _events!.criticalEvent != null) {
      _finish();
      return;
    }
    _ticker.stop();
    _progress.value = 4440 / 2600;
    _sceneProgress.value = 955 / 2600;
    _vehicleProgress.value = 1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _finish();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trigger?.removeListener(_onReplay);
    _events?.removeListener(_onEventsChanged);
    _session?.removeListener(_onSessionChanged);
    _ticker.dispose();
    _progress.dispose();
    _sceneProgress.dispose();
    _vehicleProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginVisualScope(
      variant: _loginVariant,
      reviewAction: widget.enableLoginVisualReview
          ? DevLoginVariantMenu(
              variant: _loginVariant,
              onSelected: (value) => setState(() => _loginVariant = value),
            )
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeFocus(
            excluding: _visible,
            child: IgnorePointer(
              ignoring: _visible,
              child: ExcludeSemantics(
                excluding: _visible,
                child: PremiumLoginTimeline(
                  progress: _routeLogin
                      ? _progress
                      : PremiumLoginTimeline.completed,
                  sceneProgress: _routeLogin
                      ? _sceneProgress
                      : PremiumLoginTimeline.builtScene,
                  vehicleProgress: _routeLogin
                      ? _vehicleProgress
                      : PremiumLoginTimeline.parkedVehicle,
                  headerAction: _routeLogin
                      ? ValueListenableBuilder<double>(
                          valueListenable: _progress,
                          builder: (context, value, _) => value * 2600 < 4440
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 140,
                                  ),
                                  child: TextButton(
                                    onPressed: _skipLoginIntro,
                                    child: const Text('Omitir introducción'),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        )
                      : null,
                  child: widget.child,
                ),
              ),
            ),
          ),
          if (_visible)
            if (_login)
              DevPremiumLoginPreview(
                progress: _progress,
                sceneProgress: _sceneProgress,
                vehicleProgress: _vehicleProgress,
                onSkip: _skipLoginIntro,
                onClose: _finish,
              )
            else
              Semantics(
                button: true,
                label: _closure
                    ? 'Cierre de marca URBES. Toca para cerrar'
                    : _beacon
                    ? 'Baliza flotante URBES D. Toca para cerrar'
                    : _sceneBuild
                    ? 'Construcción de escena URBES. Toca para cerrar'
                    : _vehicleMotion
                    ? 'Recorrido del vehículo URBES. Toca para cerrar'
                    : _showPremiumScene
                    ? 'Escena estática URBES Premium D. Toca para cerrar'
                    : 'Introducción URBES. Toca para continuar',
                onTap: _finish,
                child: GestureDetector(
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.opaque,
                  onTap: _finish,
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: _closure
                          ? PremiumClosurePreview(
                              progress: _progress,
                              sceneProgress: _sceneProgress,
                              vehicleProgress: _vehicleProgress,
                            )
                          : _showPremiumScene
                          ? PremiumScenePreview(
                              vehicleProgress: _vehicleMotion
                                  ? _progress
                                  : null,
                              sceneProgress: _sceneBuild
                                  ? _sceneProgress
                                  : null,
                              beaconProgress: _beacon ? _progress : null,
                            )
                          : CustomPaint(painter: BrandIntroPainter(_progress)),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Geometry is drawn in a 160 × 160 local coordinate system. At t=0, the
/// lane strokes exactly match Android's static DEV launch vector. The lane
/// contours become the shield contours by interpolating their Bezier points.
class BrandIntroPainter extends CustomPainter {
  BrandIntroPainter(this.progress) : super(repaint: progress);

  final ValueListenable<double> progress;

  static double _phase(double value, double start, double end) => Curves
      .easeInOutCubic
      .transform(((value - start) / (end - start)).clamp(0.0, 1.0));

  static double _mix(double from, double to, double t) =>
      from + (to - from) * t;

  static Path _wordmark() {
    // Provisional monoline identity, drawn in the same vector scene.
    return Path()
      ..moveTo(29, 174)
      ..lineTo(29, 188)
      ..quadraticBezierTo(29, 194, 36, 194)
      ..quadraticBezierTo(43, 194, 43, 188)
      ..lineTo(43, 174)
      ..moveTo(51, 194)
      ..lineTo(51, 174)
      ..lineTo(59, 174)
      ..quadraticBezierTo(65, 174, 65, 180)
      ..quadraticBezierTo(65, 186, 59, 186)
      ..lineTo(51, 186)
      ..moveTo(59, 186)
      ..lineTo(65, 194)
      ..moveTo(73, 194)
      ..lineTo(73, 174)
      ..lineTo(80, 174)
      ..quadraticBezierTo(87, 174, 87, 179)
      ..quadraticBezierTo(87, 184, 80, 184)
      ..lineTo(73, 184)
      ..moveTo(80, 184)
      ..quadraticBezierTo(88, 184, 88, 189)
      ..quadraticBezierTo(88, 194, 80, 194)
      ..lineTo(73, 194)
      ..moveTo(109, 174)
      ..lineTo(95, 174)
      ..lineTo(95, 194)
      ..lineTo(109, 194)
      ..moveTo(95, 184)
      ..lineTo(106, 184)
      ..moveTo(131, 175)
      ..quadraticBezierTo(117, 170, 117, 180)
      ..quadraticBezierTo(117, 184, 124, 184)
      ..quadraticBezierTo(132, 184, 132, 189)
      ..quadraticBezierTo(132, 198, 117, 193);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final reveal = 1 - _phase(t, 0.88, 1);
    final road = _phase(t, 0, 0.23);
    final car = _phase(t, 0.14, 0.48);
    final shield = _phase(t, 0.42, 0.72);
    final nodes = _phase(t, 0.58, 0.79);
    final title = _phase(t, 0.69, 0.82);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background.withValues(alpha: reveal),
    );
    if (reveal == 0) return;

    // Keep the first Flutter frame aligned with the 160 dp native mark.
    final scale = math.min(1.0, math.min(size.width / 220, size.height / 310));
    canvas.save();
    canvas.translate(size.width / 2 - 80 * scale, size.height / 2 - 80 * scale);
    canvas.scale(scale);

    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Both sides share the same end points after the morph, forming one shield.
    for (final side in [-1.0, 1.0]) {
      final x = 80 + side * 10;
      final outer = 80 + side * 46;
      final contour = Path()
        ..moveTo(_mix(x, 80, shield), _mix(40 - road * 25, 23, shield))
        ..cubicTo(
          _mix(x, 80 + side * 29, shield),
          _mix(54 - road * 17, 23, shield),
          _mix(x, outer, shield),
          _mix(68, 39, shield),
          _mix(x, outer, shield),
          _mix(80, 77, shield),
        )
        ..cubicTo(
          _mix(x, outer, shield),
          _mix(95, 111, shield),
          _mix(x, 80 + side * 25, shield),
          _mix(107 + road * 17, 130, shield),
          _mix(x, 80, shield),
          _mix(120 + road * 25, 137, shield),
        );
      canvas.drawPath(contour, linePaint);
    }

    // The short centre markings are native-static at t=0, then yield to the
    // moving vehicle; they are never an endlessly scrolling decoration.
    final dashPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: reveal * (1 - shield))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final y in [58.0, 77.0, 96.0]) {
      canvas.drawLine(Offset(80, y), Offset(80, y + 8), dashPaint);
    }

    final carAlpha =
        reveal * _phase(t, 0.14, 0.25) * (1 - _phase(t, 0.54, 0.72));
    if (carAlpha > 0) {
      canvas.save();
      canvas.translate(80, _mix(119, 73, car));
      final body = Path()
        ..moveTo(-5, -15)
        ..quadraticBezierTo(0, -18, 5, -15)
        ..lineTo(8, -7)
        ..lineTo(9, 12)
        ..quadraticBezierTo(8, 16, 4, 16)
        ..lineTo(-4, 16)
        ..quadraticBezierTo(-8, 16, -9, 12)
        ..lineTo(-8, -7)
        ..close();
      canvas.drawPath(
        body,
        Paint()..color = AppColors.primary.withValues(alpha: carAlpha),
      );
      final glazing = Path()
        ..moveTo(-5, -5)
        ..lineTo(-3.5, -11)
        ..quadraticBezierTo(0, -13, 3.5, -11)
        ..lineTo(5, -5)
        ..close();
      canvas.drawPath(
        glazing,
        Paint()..color = AppColors.background.withValues(alpha: carAlpha),
      );
      canvas.restore();
    }

    if (nodes > 0) {
      final networkPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: reveal * nodes)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final network = Path()
        ..moveTo(80, 69)
        ..lineTo(63, 87)
        ..moveTo(80, 69)
        ..lineTo(97, 87)
        ..moveTo(80, 69)
        ..lineTo(80, 108);
      canvas.drawPath(network, networkPaint);
      final nodePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: reveal * nodes);
      for (final node in const [
        Offset(80, 69),
        Offset(63, 87),
        Offset(97, 87),
        Offset(80, 108),
      ]) {
        canvas.drawCircle(node, 3.5, nodePaint);
      }
    }

    if (title > 0) {
      final metrics = _wordmark().computeMetrics().toList();
      final totalLength = metrics.fold<double>(
        0,
        (sum, metric) => sum + metric.length,
      );
      var remaining = totalLength * title;
      final drawn = Path();
      for (final metric in metrics) {
        if (remaining <= 0) break;
        drawn.addPath(
          metric.extractPath(0, math.min(remaining, metric.length)),
          Offset.zero,
        );
        remaining -= metric.length;
      }
      canvas.drawPath(
        drawn,
        Paint()
          ..color = AppColors.primary.withValues(alpha: reveal)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrandIntroPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
