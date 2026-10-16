part of 'premium_scene.dart';

/// Presentation-only destination above the live router. Never builds LoginScreen.
class PremiumClosurePreview extends StatelessWidget {
  const PremiumClosurePreview({
    super.key,
    required this.progress,
    required this.sceneProgress,
    required this.vehicleProgress,
  });
  final ValueListenable<double> progress, sceneProgress, vehicleProgress;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF8F9FA),
    child: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: PremiumClosureArtboard(
                progress: progress,
                sceneProgress: sceneProgress,
                vehicleProgress: vehicleProgress,
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Text(
              'Cierre de marca D · Toca para cerrar',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

class PremiumClosureArtboard extends StatelessWidget {
  const PremiumClosureArtboard({
    super.key,
    required this.progress,
    required this.sceneProgress,
    required this.vehicleProgress,
    this.showDestinationLabel = true,
  });
  final ValueListenable<double> progress, sceneProgress, vehicleProgress;

  /// Exclude review-only metadata when comparing vector artboards in QA.
  final bool showDestinationLabel;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 390,
    height: 844,
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFF8F9FA))),
        // The child keeps its native repaint boundaries; only its outer transform
        // changes during delivery. Vehicle projection and layer clocks stay intact.
        Positioned(
          left: 0,
          top: 0,
          child: AnimatedBuilder(
            animation: progress,
            child: SizedBox(
              width: 620,
              height: 430,
              child: PremiumSceneArtwork(
                vehicleProgress: vehicleProgress,
                sceneProgress: sceneProgress,
                hideBeacon: true,
              ),
            ),
            builder: (context, child) => Transform.translate(
              offset: Offset(
                14,
                PremiumClosureMotion.atMilliseconds(progress.value * 2600)
                    .sceneY,
              ),
              child: Transform.scale(
                scale: .6,
                alignment: Alignment.topLeft,
                child: child,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: PremiumClosureBrandPainter(progress)),
          ),
        ),
        // A neutral destination label, not a visual or functional login form.
        if (showDestinationLabel)
          Positioned(
            left: 24,
            right: 24,
            top: 340,
            child: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, value, child) => Opacity(
                opacity: PremiumClosureMotion.easeOut(
                  PremiumClosureMotion.phase(value * 2600, 4090, 4330),
                ),
                child: child,
              ),
              child: const Text(
                'Login · destino de presentación DEV\nFormulario reservado al Incremento 6',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF526078),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class PremiumClosureBrandPainter extends CustomPainter {
  PremiumClosureBrandPainter(this.progress) : super(repaint: progress);
  final ValueListenable<double> progress;
  static final Path _wordmark = _buildUrbesWordmark();
  @override
  void paint(Canvas canvas, Size size) {
    final ms = progress.value * 2600;
    final state = PremiumClosureMotion.atMilliseconds(ms);
    final beacon = PremiumBeaconMotion.atMilliseconds(ms);
    final fit = math.min(size.width / 390, size.height / 844);
    canvas.save();
    canvas.translate(
      (size.width - 390 * fit) / 2,
      (size.height - 844 * fit) / 2,
    );
    canvas.scale(fit);
    final foot = Offset(
      14 + .6 * PremiumBeaconMotion.foot.dx,
      270 + .6 * PremiumBeaconMotion.foot.dy,
    );
    if (state.shadowOpacity > 0 || beacon.waveOpacity > 1e-12) {
      canvas.save();
      canvas.translate(foot.dx, foot.dy);
      canvas.rotate(-math.pi / 6);
      if (state.shadowOpacity > 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: 2 * beacon.shadowRx,
            height: 2 * beacon.shadowRy,
          ),
          Paint()
            ..color = const Color(0xFF031B3B)
                .withValues(alpha: state.shadowOpacity),
        );
      }
      if (beacon.waveOpacity > 1e-12) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: 2 * beacon.waveRx,
            height: 2 * beacon.waveRy,
          ),
          Paint()
            ..color = const Color(0xFF14E0D3)
                .withValues(alpha: beacon.waveOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      canvas.restore();
    }
    canvas.translate(state.lockup.dx, state.lockup.dy);
    canvas.scale(state.lockupScale);
    // One continuously transformed logo picture and one wordmark throughout.
    if (beacon.opacity > 0) {
      canvas.save();
      canvas.translate(state.symbol.dx, state.symbol.dy);
      canvas.scale(2 * state.symbolScale);
      canvas.translate(
        -PremiumBeaconMotion.anchor.dx,
        -PremiumBeaconMotion.anchor.dy,
      );
      if (beacon.opacity < 1) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(255, 255, 255, beacon.opacity),
        );
      }
      canvas.drawPicture(PremiumScenePainter._pictures['brand-symbol']!);
      if (beacon.opacity < 1) canvas.restore();
      canvas.restore();
    }
    if (state.wordOpacity > 0) {
      canvas.translate(43, 11);
      canvas.drawPath(
        _wordmark,
        Paint()
          ..color = const Color(0xFF031B3B)
              .withValues(alpha: state.wordOpacity),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PremiumClosureBrandPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
