part of 'premium_home_content.dart';

/// Shared presentation copy, not a new state model or health classification.
class _SdaCopy {
  const _SdaCopy(this.status);
  final DeviceStatus? status;
  String get title => status == null
      ? 'Sin información del SDA'
      : status!.online
      ? 'SDA reportado conectado'
      : 'SDA reportado desconectado';
  String get communication {
    final seen = status?.lastSeen;
    return seen != null && seen.millisecondsSinceEpoch > 0
        ? 'Última comunicación: ${formatRelativeTime(seen)}'
        : 'Última comunicación no disponible';
  }

  IconData get icon => status == null
      ? Icons.sensors_off
      : status!.online
      ? Icons.sensors
      : Icons.link_off_rounded;
}

String _vehicleName(VehicleModel? vehicle) => vehicle == null
    ? 'Información del vehículo no disponible'
    : '${vehicle.brand} ${vehicle.model}';

class _SignatureMasthead extends StatelessWidget {
  const _SignatureMasthead({required this.name, required this.editorial});
  final String name;
  final bool editorial;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('URBES', style: _type(18, weight: FontWeight.w800)),
          const Spacer(),
          const ExcludeSemantics(
            child: SizedBox(
              width: 32,
              height: 3,
              child: DecoratedBox(decoration: BoxDecoration(color: _teal)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 26),
      Text(
        'Hola, ${name.isEmpty ? 'Usuario' : name}',
        style: _type(
          editorial ? 30 : 26,
          weight: FontWeight.w700,
        ).copyWith(letterSpacing: -.8),
      ),
      const SizedBox(height: 5),
      Text('Tu vehículo y sus últimos datos.', style: _type(14, color: _ink)),
    ],
  );
}

class _GuardianDeck extends StatelessWidget {
  const _GuardianDeck({required this.vehicle, required this.status});
  final VehicleModel? vehicle;
  final DeviceStatus? status;
  @override
  Widget build(BuildContext context) {
    final copy = _SdaCopy(status);
    return Container(
      key: const ValueKey('home-guardian-deck'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20031B3B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 10, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    constraints.maxWidth < 250 ||
                    MediaQuery.textScalerOf(context).scale(14) > 21;
                final identity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu vehículo',
                      style: _type(13, color: const Color(0xFFB8CCDF)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _vehicleName(vehicle),
                      style: _type(
                        24,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ).copyWith(letterSpacing: -.6),
                    ),
                    if (vehicle != null) ...[
                      const SizedBox(height: 14),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF74869D)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'Placa ${vehicle!.plate}',
                            style: _type(13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
                const art = ExcludeSemantics(
                  child: RepaintBoundary(
                    child: SizedBox(
                      height: 142,
                      width: 120,
                      child: ClipRect(
                        child: CustomPaint(painter: _DeckRoadArt()),
                      ),
                    ),
                  ),
                );
                return stack
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          identity,
                          const Align(
                            alignment: Alignment.centerRight,
                            child: art,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: identity),
                          art,
                        ],
                      );
              },
            ),
          ),
          Container(
            key: const ValueKey('home-availability'),
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFF0B2B4E),
              border: Border(top: BorderSide(color: Color(0xFF31506B))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SignalGlyph(copy: copy, dark: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        copy.title,
                        style: _type(
                          17,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  copy.communication,
                  style: _type(13, color: const Color(0xFFD3E1ED)),
                ),
                const SizedBox(height: 5),
                Text(
                  'Disponibilidad de comunicación reportada.',
                  style: _type(12, color: const Color(0xFFB8CCDF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalGlyph extends StatelessWidget {
  const _SignalGlyph({required this.copy, required this.dark});
  final _SdaCopy copy;
  final bool dark;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160),
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF173D59) : const Color(0xFFE1EFEE),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: copy.status?.online == true
            ? dark
                  ? _aqua
                  : _teal
            : dark
            ? const Color(0xFF8296A8)
            : const Color(0xFF879395),
      ),
    ),
    child: Icon(copy.icon, size: 20, color: dark ? Colors.white : _teal),
  );
}

class _SignalFlow extends StatelessWidget {
  const _SignalFlow({required this.vehicle, required this.status});
  final VehicleModel? vehicle;
  final DeviceStatus? status;
  @override
  Widget build(BuildContext context) {
    final copy = _SdaCopy(status);
    return Column(
      key: const ValueKey('home-signal-flow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: _navy),
        const SizedBox(height: 20),
        Text('Enlace del SDA', style: _type(13, color: _ink)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedSize(
                alignment: Alignment.topLeft,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: Text(
                  copy.title,
                  key: const ValueKey('home-availability'),
                  style: _type(
                    32,
                    weight: FontWeight.w600,
                  ).copyWith(height: 1.16, letterSpacing: -1.1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _SignalGlyph(copy: copy, dark: false),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Disponibilidad de comunicación reportada.',
          style: _type(13, color: _ink),
        ),
        const SizedBox(height: 26),
        // A typographic reading rail, not a map or a network diagram.
        Container(
          padding: const EdgeInsets.only(left: 18),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: _teal, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vehicleName(vehicle),
                style: _type(21, weight: FontWeight.w700),
              ),
              if (vehicle != null) ...[
                const SizedBox(height: 5),
                Text('Placa ${vehicle!.plate}', style: _type(14, color: _ink)),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: _line),
              const SizedBox(height: 16),
              Text(copy.communication, style: _type(14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignatureSection extends StatelessWidget {
  const _SignatureSection({required this.editorial, required this.child});
  final bool editorial;
  final Widget child;
  @override
  Widget build(BuildContext context) => editorial
      ? child
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        );
}

/// Original static road/vehicle illustration, no location or live tracking.
class _DeckRoadArt extends CustomPainter {
  const _DeckRoadArt();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 142);
    final road = Path()
      ..moveTo(154, -22)
      ..cubicTo(70, 22, 145, 90, 5, 164);
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFF173D59)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 48,
    );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFF31536C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 50,
    );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFF153752)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 47,
    );
    for (final metric in road.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 19) {
        canvas.drawPath(
          metric.extractPath(start, start + 7),
          Paint()
            ..color = const Color(0xFF7996A8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      }
    }
    canvas.translate(86, 72);
    canvas.rotate(.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-21, -34, 46, 80),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0x66000C20),
    );
    for (final x in [-22.0, 16.0]) {
      for (final y in [-24.0, 20.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 7, 16),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF071524),
        );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -39, 40, 80),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFE8F0F3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -36, 32, 72),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white,
    );
    final glass = Paint()..color = const Color(0xFF28516A);
    canvas.drawPath(
      Path()
        ..moveTo(-14, -19)
        ..lineTo(14, -19)
        ..lineTo(11, -6)
        ..lineTo(-11, -6)
        ..close(),
      glass,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-11, 15)
        ..lineTo(11, 15)
        ..lineTo(14, 25)
        ..lineTo(-14, 25)
        ..close(),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -3, 22, 15),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFDCE6EB),
    );
    for (final x in [-14.0, 8.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -35, 6, 4),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF14E0D3),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DeckRoadArt oldDelegate) => false;
}
