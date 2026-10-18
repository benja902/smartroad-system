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
      if (!editorial) const _GuardianBrand(),
      if (editorial)
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
      SizedBox(height: editorial ? 26 : 18),
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
