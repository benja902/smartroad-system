part of 'premium_home_content.dart';

class _GuardianBrand extends StatelessWidget {
  const _GuardianBrand();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'URBES',
    image: true,
    child: const ExcludeSemantics(
      child: SizedBox(
        key: ValueKey('guardian-official-brand'),
        width: 120,
        height: 36,
        child: RepaintBoundary(
          child: CustomPaint(painter: _GuardianBrandPainter()),
        ),
      ),
    ),
  );
}

/// Reuses the official vector lockup at Login's completed frame, unmodified.
class _GuardianBrandPainter extends CustomPainter {
  const _GuardianBrandPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.height / 36);
    canvas.translate(-24, -27);
    PremiumClosureBrandPainter(const AlwaysStoppedAnimation(4440 / 2600))
        .paint(canvas, const Size(390, 844));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GuardianBrandPainter oldDelegate) => false;
}

class _GuardianDeck extends StatelessWidget {
  const _GuardianDeck({
    required this.vehicle,
    required this.status,
    required this.artwork,
  });
  final VehicleModel? vehicle;
  final DeviceStatus? status;
  final GuardianArtwork artwork;
  @override
  Widget build(BuildContext context) {
    final copy = _SdaCopy(status);
    return Container(
      key: const ValueKey('home-guardian-deck'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18031B3B),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu vehículo',
                  style: _type(13, color: const Color(0xFFC5D2E5)),
                ),
                const SizedBox(height: 4),
                Text(
                  _vehicleName(vehicle),
                  style: _type(
                    24,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ).copyWith(letterSpacing: -.5),
                ),
                if (vehicle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Placa ${vehicle!.plate}',
                    style: _type(14, color: const Color(0xFFD3E1ED)),
                  ),
                ],
              ],
            ),
          ),
          ExcludeSemantics(
            child: RepaintBoundary(
              child: SizedBox(
                key: ValueKey('guardian-art-${artwork.name}'),
                height: 120,
                child: ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CustomPaint(
                      painter: artwork == GuardianArtwork.lineArt
                          ? const _VehicleOutline()
                          : const _GuardianIsometricArt(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            key: const ValueKey('home-availability'),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy.title,
                              style: _type(
                                16,
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              copy.communication,
                              style: _type(13, color: const Color(0xFFD3E1ED)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static reuse of D's native 2.5D vehicle on a small matching road plane.
/// Neither vehicle geometry nor Splash choreography is altered.
class _GuardianIsometricArt extends CustomPainter {
  const _GuardianIsometricArt();
  static final _vehicle = PremiumVehiclePainter(
    const AlwaysStoppedAnimation(600 / 2600),
  );
  @override
  void paint(Canvas canvas, Size size) {
    final pose = PremiumVehicleMotion.atMilliseconds(600);
    final center = PremiumVehicleMotion.project(pose.x, pose.y);
    final scale = (size.width / 250).clamp(0.0, size.height / 126);
    canvas.save();
    canvas.translate(
      (size.width - 250 * scale) / 2,
      (size.height - 126 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(125 - center.dx, 63 - center.dy);
    final corners = [
      PremiumVehicleMotion.project(pose.x - 95, pose.y - 27),
      PremiumVehicleMotion.project(pose.x + 95, pose.y - 27),
      PremiumVehicleMotion.project(pose.x + 95, pose.y + 27),
      PremiumVehicleMotion.project(pose.x - 95, pose.y + 27),
    ];
    final road = Path()..addPolygon(corners, true);
    canvas.drawPath(
      road.shift(const Offset(0, 5)),
      Paint()..color = const Color(0xFF071627),
    );
    canvas.drawPath(road, Paint()..color = const Color(0xFF355269));
    for (var x = -90.0; x < 90; x += 24) {
      canvas.drawLine(
        PremiumVehicleMotion.project(pose.x + x, pose.y),
        PremiumVehicleMotion.project(pose.x + x + 12, pose.y),
        Paint()
          ..color = const Color(0xFFD8E5EC)
          ..strokeWidth = 1.5,
      );
    }
    _vehicle.paint(canvas, const Size(620, 430));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GuardianIsometricArt oldDelegate) => false;
}

class _GuardianConnectivity extends StatelessWidget {
  const _GuardianConnectivity({required this.status});
  final DeviceStatus? status;
  @override
  Widget build(BuildContext context) {
    final modem = status?.modem;
    final gnss = status?.gnss;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Conectividad reportada',
            style: _type(16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = MediaQuery.textScalerOf(context).scale(14) > 21;
              final mobile = _ConnectionReading(
                icon: Icons.signal_cellular_alt,
                label: 'Red móvil',
                value: modem?.tech ?? 'Tecnología no informada',
                detail: modem == null
                    ? 'Registro no informado'
                    : modem.registered
                    ? 'Registro celular reportado'
                    : 'Sin registro celular reportado',
              );
              final position = _ConnectionReading(
                icon: Icons.satellite_alt_outlined,
                label: 'GNSS',
                value: gnss == null
                    ? 'Sin datos'
                    : gnss.fix
                    ? 'Fix reportado'
                    : 'Sin fix reportado',
                detail: 'Según el dato recibido',
              );
              return stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [mobile, const SizedBox(height: 14), position],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mobile),
                        const SizedBox(width: 20),
                        Expanded(child: position),
                      ],
                    );
            },
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _line),
          Padding(
            key: const ValueKey('home-position'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Posición recibida', style: _type(12, color: _ink)),
                const SizedBox(height: 4),
                Text(
                  gnss == null
                      ? 'Sin datos de ubicación'
                      : !gnss.fix
                      ? 'Sin coordenadas para mostrar'
                      : '${gnss.latitude.toStringAsFixed(5)}, ${gnss.longitude.toStringAsFixed(5)}',
                  style: _type(13),
                ),
              ],
            ),
          ),
          if (status?.power?.batteryV != null ||
              status?.modem?.rssiDbm != null ||
              status?.storage != null)
            ExpansionTile(
              key: const PageStorageKey('guardian-diagnostics'),
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
                  ? AnimationStyle.noAnimation
                  : const AnimationStyle(duration: Duration(milliseconds: 180)),
              title: Text(
                'Datos técnicos recibidos',
                style: _type(14, color: _teal),
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status?.power?.batteryV != null)
                  _DataLine(
                    label: 'Voltaje de batería',
                    value: '${status!.power!.batteryV!.toStringAsFixed(2)} V',
                  ),
                if (status?.modem?.rssiDbm != null)
                  _DataLine(
                    label: 'Intensidad de señal',
                    value: '${status!.modem!.rssiDbm} dBm',
                  ),
                if (status?.storage != null)
                  _DataLine(
                    label: 'microSD',
                    value: status!.storage!.present
                        ? 'Presencia reportada'
                        : 'Ausencia reportada',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ConnectionReading extends StatelessWidget {
  const _ConnectionReading({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });
  final IconData icon;
  final String label, value, detail;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 18, color: _teal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: _type(13, color: _ink)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(value, style: _type(15, weight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(detail, style: _type(12, color: _ink)),
    ],
  );
}
