part of 'premium_home_content.dart';

/// Two treatments of one header. Same official lockup, same owner and copy.
class _GuardianHeader extends StatelessWidget {
  const _GuardianHeader({required this.name, required this.treatment});
  final String name;
  final GuardianHeader treatment;
  @override
  Widget build(BuildContext context) {
    final signature = treatment == GuardianHeader.signature;
    return Stack(
      key: ValueKey('guardian-header-${treatment.name}'),
      clipBehavior: Clip.none,
      children: [
        if (signature)
          Positioned(
            top: -20,
            left: -20,
            right: -20,
            bottom: -8,
            child: const ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFECF2F5), Color(0xFFF8F9FA)],
                  ),
                ),
              ),
            ),
          ),
        if (signature)
          const Positioned(
            right: 0,
            top: 0,
            width: 68,
            height: 44,
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(painter: _HeaderRouteMotif()),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GuardianBrand(),
              const SizedBox(height: 20),
              Text(
                'Hola, ${name.isEmpty ? 'Usuario' : name}',
                style: _type(
                  28,
                  weight: FontWeight.w700,
                ).copyWith(letterSpacing: -.7, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu vehículo y sus últimos datos.',
                style: _type(14, color: _ink).copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quiet brand illustration only: no location pin, telemetry or live signal.
class _HeaderRouteMotif extends CustomPainter {
  const _HeaderRouteMotif();
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0x17335369)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(2, 40)
        ..lineTo(18, 40)
        ..cubicTo(38, 40, 26, 8, 48, 8)
        ..lineTo(66, 8),
      pen,
    );
    canvas.drawPath(
      Path()
        ..moveTo(2, 32)
        ..lineTo(15, 32)
        ..cubicTo(28, 32, 23, 0, 47, 0)
        ..lineTo(66, 0),
      pen,
    );
    canvas.drawLine(
      const Offset(52, 8),
      const Offset(62, 8),
      Paint()
        ..color = const Color(0x80006D68)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HeaderRouteMotif oldDelegate) => false;
}
