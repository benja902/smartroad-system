part of 'premium_home_content.dart';

// Increment A: selectable in DEV only. Geometry is illustrative, not mapping.
class _StudioHeader extends StatelessWidget {
  const _StudioHeader({
    required this.name,
    required this.onOpenProfile,
    this.showBrand = true,
  });
  final String name;
  final VoidCallback? onOpenProfile;
  final bool showBrand;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: ExcludeSemantics(
          child: RepaintBoundary(child: CustomPaint(painter: _StudioMap())),
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBrand)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const UrbesBrandLockup(),
                if (onOpenProfile != null)
                  ProfileHeaderAction(
                    key: const ValueKey('studio-profile'),
                    onPressed: onOpenProfile!,
                  ),
              ],
            ),
          if (showBrand) const SizedBox(height: 16),
          Text(
            'Hola, ${name.isEmpty ? 'Usuario' : name}',
            style: _type(
              26,
              weight: FontWeight.w800,
            ).copyWith(letterSpacing: -.8, height: 1.2),
          ),
          const SizedBox(height: 5),
          Text(
            'Tu vehículo y sus últimos datos',
            style: _type(14, color: _ink),
          ),
        ],
      ),
    ],
  );
}

class _StudioMap extends CustomPainter {
  const _StudioMap();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width * .46, 0);
    final streets = Paint()
      ..color = const Color(0xFFEBF1F3)
      ..strokeWidth = 1.2;
    for (var i = -2; i < 8; i++) {
      canvas.drawLine(
        Offset(i * 38, -30),
        Offset(i * 38 + 85, size.height),
        streets,
      );
      canvas.drawLine(
        Offset(-40, i * 32),
        Offset(size.width, i * 32 - 70),
        streets,
      );
    }
    final route = Path()
      ..moveTo(25, -12)
      ..cubicTo(20, 45, 130, 35, 145, size.height);
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF8CE6DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // No live marker, geographic coordinates or data-driven state.
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StudioMap oldDelegate) => false;
}

class _StudioHero extends StatelessWidget {
  const _StudioHero({required this.vehicle, required this.status});
  final VehicleModel? vehicle;
  final DeviceStatus? status;
  @override
  Widget build(BuildContext context) {
    final copy = _SdaCopy(status);
    return Container(
      key: const ValueKey('studio-hero'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF073A51), Color(0xFF03243C)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18031B3B),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _StudioBackdrop(),
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
                    style: _type(13, color: const Color(0xFFC5D7E5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _vehicleName(vehicle),
                    style: _type(
                      24,
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ).copyWith(letterSpacing: -.6),
                  ),
                  if (vehicle != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF145571),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Placa ${vehicle!.plate}',
                        style: _type(
                          12,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // User-supplied cutout for DEV art review, not a photo of this vehicle.
            const ExcludeSemantics(
              child: RepaintBoundary(child: _StudioVehicleImage()),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
              color: const Color(0xEB031B3B),
              child: Row(
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
                              15,
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            copy.communication,
                            style: _type(12, color: const Color(0xFFD3E1ED)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _studioSurface() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFE7EDF2)),
  boxShadow: const [
    BoxShadow(color: Color(0x05031B3B), blurRadius: 14, offset: Offset(0, 4)),
  ],
);

/// Asset stays independent of the studio background and functional labels.
class _StudioVehicleImage extends StatelessWidget {
  const _StudioVehicleImage();
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2.2,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) => Image.asset(
          'docs/ui_ux/premium_phase1/home_review/auto.webp',
          key: const ValueKey('studio-vehicle-image'),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          cacheWidth:
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, 1000),
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => const CustomPaint(
            key: ValueKey('studio-vehicle-fallback'),
            painter: _GuardianIsometricArt(),
          ),
        ),
      ),
    ),
  );
}

/// Static studio lighting and abstract road; no image tint or live map.
class _StudioBackdrop extends CustomPainter {
  const _StudioBackdrop();
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.35, .05),
          radius: .9,
          colors: [Color(0xCC52728C), Color(0x44304B65), Color(0x00031B3B)],
          stops: [0, .55, 1],
        ).createShader(bounds),
    );
    final w = size.width, h = size.height;
    final road = Path()
      ..moveTo(-.1 * w, .8 * h)
      ..cubicTo(.22 * w, .73 * h, .8 * w, .8 * h, 1.1 * w, .5 * h);
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFF0A253B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .14,
    );
    for (final dy in [-h * .045, h * .045]) {
      canvas.drawPath(
        road.shift(Offset(0, dy)),
        Paint()
          ..color = const Color(0x2214E0D3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      canvas.drawPath(
        road.shift(Offset(0, dy)),
        Paint()
          ..color = const Color(0xB364DED8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    final shadow = Rect.fromCenter(
      center: Offset(w * .52, h * .71),
      width: w * .78,
      height: h * .12,
    );
    canvas.drawOval(
      shadow,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xAA000C1C), Color(0x00000C1C)],
        ).createShader(shadow),
    );
  }

  @override
  bool shouldRepaint(_StudioBackdrop oldDelegate) => false;
}

class _StudioDevice extends StatelessWidget {
  const _StudioDevice({required this.status});
  final DeviceStatus? status;
  @override
  Widget build(BuildContext context) {
    final modem = status?.modem;
    final gnss = status?.gnss;
    final cells = [
      _StudioMetric(
        icon: Icons.signal_cellular_alt_rounded,
        label: 'Red móvil',
        value: modem?.tech ?? 'Sin tecnología informada',
        detail: modem == null
            ? 'Registro no informado'
            : modem.registered
            ? 'Registro reportado'
            : 'Sin registro reportado',
      ),
      _StudioMetric(
        icon: Icons.satellite_alt_outlined,
        label: 'Ubicación GNSS',
        value: gnss == null
            ? 'Sin datos'
            : gnss.fix
            ? 'Fix reportado'
            : 'Sin fix reportado',
        detail: 'Según el dato recibido',
      ),
      _StudioMetric(
        icon: Icons.battery_std_outlined,
        label: 'Batería (SDA)',
        value: status?.power?.batteryV == null
            ? 'Sin dato'
            : '${status!.power!.batteryV!.toStringAsFixed(2)} V',
        detail: 'Voltaje recibido',
      ),
    ];
    return Container(
      key: const ValueKey('studio-device'),
      decoration: _studioSurface(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estado del dispositivo',
            style: _type(15, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final scaledText = MediaQuery.textScalerOf(context).scale(14);
              // Same widths as the actual Row: two 18 dp separators.
              // Measure each style with the real TextScaler, including Android's
              // nonlinear scaling, instead of rejecting an accessibility setting.
              final columnWidth = (constraints.maxWidth - 36) / 3;
              final columns = cells.every(
                (cell) => cell.fitsColumn(context, columnWidth),
              );
              final Widget indicators;
              if (!columns) {
                indicators = Column(
                  key: const ValueKey('studio-bento-vertical'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      cells[i],
                      if (i != cells.length - 1)
                        const Divider(color: _line, height: 18),
                    ],
                  ],
                );
              } else {
                indicators = IntrinsicHeight(
                  key: const ValueKey('studio-bento-columns'),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < cells.length; i++) ...[
                        if (i > 0)
                          const VerticalDivider(width: 18, color: _line),
                        Expanded(child: cells[i]),
                      ],
                    ],
                  ),
                );
              }
              if (!HomeVisualPreview.layoutDiagnosticsOf(context)) {
                return indicators;
              }
              final media = MediaQuery.sizeOf(context);
              final view = View.of(context);
              final window = view.physicalSize / view.devicePixelRatio;
              final reason = columns
                  ? 'los textos caben en las tres columnas'
                  : 'algún texto necesita más espacio para conservar legibilidad';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  indicators,
                  const SizedBox(height: 12),
                  Container(
                    key: const ValueKey('studio-layout-diagnostics'),
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFF0F5F5),
                    child: SelectableText(
                      'Diagnóstico DEV · Bento\n'
                      'Ventana lógica: ${window.width.toStringAsFixed(1)} × ${window.height.toStringAsFixed(1)} dp\n'
                      'MediaQuery: ${media.width.toStringAsFixed(1)} × ${media.height.toStringAsFixed(1)} dp\n'
                      'Ancho interior: ${constraints.maxWidth.toStringAsFixed(1)} dp\n'
                      'Ancho por columna: ${columnWidth.toStringAsFixed(1)} dp\n'
                      'Texto base 14 → ${scaledText.toStringAsFixed(2)} (${(scaledText / 14 * 100).toStringAsFixed(1)} %)\n'
                      'Densidad: ${view.devicePixelRatio.toStringAsFixed(2)} px/dp\n'
                      'Distribución: ${columns ? '3 columnas' : 'vertical'}\n'
                      'Motivo: $reason',
                      style: _type(12),
                    ),
                  ),
                ],
              );
            },
          ),
          if (status?.modem?.rssiDbm != null || status?.storage != null)
            ExpansionTile(
              key: const PageStorageKey('studio-diagnostics'),
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
                  ? AnimationStyle.noAnimation
                  : const AnimationStyle(duration: Duration(milliseconds: 180)),
              title: Text(
                'Datos técnicos recibidos',
                style: _type(12, color: _teal),
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _StudioMetric extends StatelessWidget {
  const _StudioMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });
  final IconData icon;
  final String label, value, detail;
  TextStyle get _labelStyle => _type(11, color: _ink);
  TextStyle get _valueStyle => _type(14, weight: FontWeight.w800);
  TextStyle get _detailStyle => _type(10, color: _ink);

  bool fitsColumn(BuildContext context, double width) {
    if (width < 33) return false; // Icon and its padding must fit as well.
    final base = DefaultTextStyle.of(context).style;
    for (final sample in [
      (label, _labelStyle, 2),
      (value, _valueStyle, 3),
      (detail, _detailStyle, 3),
    ]) {
      final painter = TextPainter(
        text: TextSpan(text: sample.$1, style: base.merge(sample.$2)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: sample.$3,
      )..layout(maxWidth: width);
      final fits = !painter.didExceedMaxLines;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFE4FAF6),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 23, color: _teal),
      ),
      const SizedBox(height: 8),
      Text(label, style: _labelStyle),
      const SizedBox(height: 4),
      Text(value, style: _valueStyle),
      const SizedBox(height: 4),
      Text(detail, style: _detailStyle),
    ],
  );
}

class _StudioPosition extends StatelessWidget {
  const _StudioPosition({required this.status});
  final DeviceStatus? status;
  @override
  Widget build(BuildContext context) {
    final gnss = status?.gnss;
    return Container(
      key: const ValueKey('home-position'),
      padding: const EdgeInsets.all(16),
      decoration: _studioSurface(),
      child: _ConnectionReading(
        icon: Icons.location_on_rounded,
        label: 'Última posición reportada',
        value: gnss == null
            ? 'Sin datos de ubicación'
            : !gnss.fix
            ? 'Sin coordenadas para mostrar'
            : '${gnss.latitude.toStringAsFixed(5)}, ${gnss.longitude.toStringAsFixed(5)}',
        detail: gnss?.fix == true
            ? 'Posición incluida en el dato recibido.'
            : '',
        valueSize: 13,
      ),
    );
  }
}
