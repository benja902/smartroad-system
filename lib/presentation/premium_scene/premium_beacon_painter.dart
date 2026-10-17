part of 'premium_scene.dart';

/// Reuses the original logo picture; no path morphing or duplicate symbol.
class PremiumBeaconPainter extends CustomPainter {
  PremiumBeaconPainter(this.progress) : super(repaint: progress);
  final ValueListenable<double> progress;
  @override
  void paint(Canvas canvas, Size size) {
    final state = PremiumBeaconMotion.atMilliseconds(progress.value * 2600);
    if (state.opacity <= 0) return;
    final scale = math.min(size.width / 620, size.height / 430);
    canvas.save();
    canvas.translate(
      (size.width - 620 * scale) / 2,
      (size.height - 430 * scale) / 2,
    );
    canvas.scale(scale);
    // The web scene uses .6 world-to-phone scale. Convert its pixel effects
    // back to this 620x430 scene before the device fit transform.
    canvas.save();
    canvas.translate(PremiumBeaconMotion.foot.dx, PremiumBeaconMotion.foot.dy);
    canvas.rotate(-math.pi / 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 2 * state.shadowRx / .6,
        height: 2 * state.shadowRy / .6,
      ),
      Paint()
        ..color = const Color(0xFF031B3B)
            .withValues(alpha: state.shadowOpacity),
    );
    if (state.waveOpacity > 1e-12) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 2 * state.waveRx / .6,
          height: 2 * state.waveRy / .6,
        ),
        Paint()
          ..color = const Color(0xFF14E0D3).withValues(alpha: state.waveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 / .6,
      );
    }
    canvas.restore();
    canvas.translate(state.offset.dx / .6, state.offset.dy / .6);
    canvas.translate(
      PremiumBeaconMotion.anchor.dx,
      PremiumBeaconMotion.anchor.dy,
    );
    canvas.scale(state.scale);
    canvas.translate(
      -PremiumBeaconMotion.anchor.dx,
      -PremiumBeaconMotion.anchor.dy,
    );
    if (state.opacity < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(255, 255, 255, state.opacity),
      );
    }
    canvas.drawPicture(PremiumScenePainter._pictures['brand-symbol']!);
    if (state.opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PremiumBeaconPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
