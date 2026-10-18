import 'package:flutter/material.dart';

import '../../presentation/premium_scene/premium_scene.dart';
import '../../presentation/premium_scene/premium_vehicle.dart';

import '../../core/utils/date_time_formatting.dart';
import '../../models/accident_event.dart';
import '../../models/device_status.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/screen_entrance.dart';
import 'home_visual_preview.dart';
import 'widgets/recent_alerts_preview.dart';

part 'signature_home_directions.dart';
part 'guardian_deck_refinement.dart';
part 'guardian_header.dart';

// Local review palette. No change to AppTheme or the global Design System.
const _navy = Color(0xFF031B3B);
const _teal = Color(0xFF006D68);
const _aqua = Color(0xFF14E0D3);
const _ink = Color(0xFF44474D);
const _line = Color(0xFFE0E6EB);

/// Presentation only: HomeScreen owns subscriptions, classification and actions.
/// All review compositions reuse the same data sections and callbacks.
class PremiumHomeContent extends StatelessWidget {
  const PremiumHomeContent({
    super.key,
    required this.variant,
    required this.userName,
    required this.vehicle,
    required this.status,
    required this.events,
    required this.eventError,
    required this.attention,
    required this.onOpenAlerts,
    this.guardianArtwork = GuardianArtwork.defaultVariant,
    this.guardianHeader = GuardianHeader.defaultVariant,
  });

  final HomePreviewVariant variant;
  final String userName;
  final VehicleModel? vehicle;
  final DeviceStatus? status;
  final List<AccidentEvent> events;
  final bool eventError;
  final Widget? attention;
  final VoidCallback onOpenAlerts;
  final GuardianArtwork guardianArtwork;
  final GuardianHeader guardianHeader;

  @override
  Widget build(BuildContext context) {
    final vehicleFocus = variant == HomePreviewVariant.vehicleFocus;
    final crafted =
        variant == HomePreviewVariant.guardianDeck ||
        variant == HomePreviewVariant.signalFlow;
    final editorial = variant == HomePreviewVariant.signalFlow;
    final name = userName.trim().split(RegExp(r'\s+')).first;
    final vehicleSection = _VehicleIdentity(
      vehicle: vehicle,
      prominent: vehicleFocus,
    );
    final report = _Availability(status: status, prominent: !vehicleFocus);
    return ScreenEntrance(
      builder: (context, entrance) => Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                key: const PageStorageKey('premium-home-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    sliver: SliverList.list(
                      children: [
                        if (variant == HomePreviewVariant.guardianDeck)
                          _GuardianHeader(name: name, treatment: guardianHeader)
                        else if (crafted)
                          _SignatureMasthead(name: name, editorial: editorial),
                        if (!crafted)
                          Text(
                            'URBES',
                            style: _type(18, weight: FontWeight.w800),
                          ),
                        if (!crafted) const SizedBox(height: 24),
                        if (!crafted)
                          EntranceSection(
                            animation: entrance,
                            fade: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${name.isEmpty ? 'Usuario' : name}',
                                  style: _type(28, weight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tu vehículo y sus últimos datos.',
                                  style: _type(14, color: _ink),
                                ),
                              ],
                            ),
                          ),
                        if (attention != null) ...[
                          const SizedBox(height: 20),
                          attention!,
                        ],
                        SizedBox(
                          height: variant == HomePreviewVariant.guardianDeck
                              ? 20
                              : 24,
                        ),
                        if (crafted)
                          editorial
                              ? _SignalFlow(vehicle: vehicle, status: status)
                              : _GuardianDeck(
                                  vehicle: vehicle,
                                  status: status,
                                  artwork: guardianArtwork,
                                )
                        else if (vehicleFocus) ...[
                          vehicleSection,
                          const SizedBox(height: 24),
                          report,
                        ] else ...[
                          report,
                          const SizedBox(height: 20),
                          vehicleSection,
                        ],
                        SizedBox(
                          height: variant == HomePreviewVariant.guardianDeck
                              ? 20
                              : 24,
                        ),
                        if (variant == HomePreviewVariant.guardianDeck)
                          _GuardianConnectivity(status: status)
                        else if (crafted)
                          _SignatureSection(
                            editorial: editorial,
                            child: _PositionReport(status: status),
                          )
                        else
                          _PositionReport(status: status),
                        if (variant != HomePreviewVariant.guardianDeck) ...[
                          const SizedBox(height: 20),
                          _Connectivity(status: status),
                        ],
                        SizedBox(
                          height: variant == HomePreviewVariant.guardianDeck
                              ? 22
                              : 28,
                        ),
                        if (eventError) ...[
                          Semantics(
                            liveRegion: true,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1DA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'No se pudo completar una operación de alertas. '
                                'Los registros mostrados pueden ser anteriores.',
                                key: const ValueKey('home-event-error'),
                                style: _type(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        RecentAlertsPreview(
                          events: events,
                          neutralEmpty: true,
                          editorial: crafted,
                          guardian: variant == HomePreviewVariant.guardianDeck,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const ValueKey('home-open-alerts'),
                            onPressed: onOpenAlerts,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                            label: const Text('Consultar alertas'),
                            style: TextButton.styleFrom(
                              foregroundColor: _teal,
                              backgroundColor:
                                  variant == HomePreviewVariant.guardianDeck
                                  ? const Color(0xFFE7F2F0)
                                  : null,
                              minimumSize: const Size(48, 48),
                              textStyle: _type(14, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _type(
  double size, {
  Color color = _navy,
  FontWeight weight = FontWeight.w500,
}) => TextStyle(
  fontFamily: 'Manrope',
  fontSize: size,
  height: 1.4,
  color: color,
  fontWeight: weight,
);

class _VehicleIdentity extends StatelessWidget {
  const _VehicleIdentity({required this.vehicle, required this.prominent});
  final VehicleModel? vehicle;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final color = prominent ? Colors.white : _navy;
    return Container(
      key: ValueKey(prominent ? 'home-vehicle-hero' : 'home-vehicle-compact'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: prominent ? _navy : Colors.white,
        borderRadius: BorderRadius.circular(prominent ? 24 : 16),
        border: prominent ? null : Border.all(color: _line),
        boxShadow: prominent
            ? const [
                BoxShadow(
                  color: Color(0x18031B3B),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu vehículo',
            style: _type(13, color: prominent ? const Color(0xFFC5D2E5) : _ink),
          ),
          const SizedBox(height: 8),
          Text(
            vehicle == null
                ? 'Información del vehículo no disponible'
                : '${vehicle!.brand} ${vehicle!.model}',
            style: _type(
              prominent ? 22 : 18,
              color: color,
              weight: FontWeight.w700,
            ),
          ),
          if (vehicle != null) ...[
            const SizedBox(height: 10),
            Text('Placa ${vehicle!.plate}', style: _type(14, color: color)),
          ],
          if (prominent) ...[
            const SizedBox(height: 10),
            const ExcludeSemantics(
              child: SizedBox(
                height: 70,
                width: double.infinity,
                child: RepaintBoundary(
                  child: CustomPaint(painter: _VehicleOutline()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Availability extends StatelessWidget {
  const _Availability({required this.status, required this.prominent});
  final DeviceStatus? status;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final copy = _SdaCopy(status);
    return Container(
      key: const ValueKey('home-availability'),
      padding: prominent ? const EdgeInsets.all(20) : EdgeInsets.zero,
      decoration: prominent
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status == null
                ? Icons.sensors_off
                : status!.online
                ? Icons.sensors
                : Icons.link_off_rounded,
            color: _teal,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            copy.title,
            style: _type(prominent ? 24 : 19, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Disponibilidad de comunicación reportada.',
            style: _type(13, color: _ink),
          ),
          const SizedBox(height: 12),
          Text(copy.communication, style: _type(14)),
        ],
      ),
    );
  }
}

class _PositionReport extends StatelessWidget {
  const _PositionReport({required this.status});
  final DeviceStatus? status;

  @override
  Widget build(BuildContext context) {
    final position = status?.gnss;
    return Container(
      key: const ValueKey('home-position'),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _line),
          bottom: BorderSide(color: _line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: _teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posición GNSS',
                  style: _type(16, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  position == null
                      ? 'Sin datos de ubicación'
                      : !position.fix
                      ? 'Sin fix GNSS en el dato recibido'
                      : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                  style: _type(15),
                ),
                if (position?.fix == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Posición incluida en el dato recibido.',
                    style: _type(13, color: _ink),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Connectivity extends StatelessWidget {
  const _Connectivity({required this.status});
  final DeviceStatus? status;

  @override
  Widget build(BuildContext context) {
    final modem = status?.modem;
    final position = status?.gnss;
    return ExpansionTile(
      key: const PageStorageKey('home-connectivity'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: _teal,
      textColor: _navy,
      expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(duration: Duration(milliseconds: 180)),
      title: Text(
        'Conectividad reportada',
        style: _type(15, weight: FontWeight.w700),
      ),
      subtitle: Text('Red celular y GNSS', style: _type(13, color: _ink)),
      children: [
        _DataLine(
          label: 'Tecnología de red',
          value: modem?.tech ?? 'No informada',
        ),
        _DataLine(
          label: 'Registro celular',
          value: modem == null
              ? 'Sin datos'
              : modem.registered
              ? 'Registrado en el dato recibido'
              : 'Sin registro reportado',
        ),
        _DataLine(
          label: 'Estado GNSS',
          value: position == null
              ? 'Sin datos'
              : position.fix
              ? 'Fix en el dato recibido'
              : 'Sin fix en el dato recibido',
        ),
      ],
    );
  }
}

class _DataLine extends StatelessWidget {
  const _DataLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _type(13, color: _ink)),
        Text(value, style: _type(14)),
      ],
    ),
  );
}

/// Native outline adapted from #vehicle-profile in the existing premium HTML.
/// Decorative generic silhouette; not a depiction of the associated model.
class _VehicleOutline extends CustomPainter {
  const _VehicleOutline();
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 340).clamp(0.0, size.height / 126);
    canvas.translate((size.width - 340 * scale) / 2, 0);
    canvas.scale(scale);
    final pen = Paint()
      ..color = const Color(0xFFDAE4F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    final body = Path()
      ..moveTo(24, 77)
      ..lineTo(31, 58)
      ..lineTo(82, 47)
      ..lineTo(122, 18)
      ..lineTo(203, 18)
      ..lineTo(247, 49)
      ..lineTo(298, 58)
      ..lineTo(313, 76)
      ..lineTo(313, 96)
      ..lineTo(24, 96)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0x08FFFFFF));
    canvas.drawPath(body, pen);
    canvas.drawPath(
      Path()
        ..moveTo(128, 25)
        ..lineTo(97, 47)
        ..lineTo(157, 47)
        ..lineTo(157, 25)
        ..close()
        ..moveTo(166, 25)
        ..lineTo(166, 47)
        ..lineTo(231, 47)
        ..lineTo(200, 25)
        ..close()
        ..moveTo(165, 53)
        ..lineTo(165, 83)
        ..moveTo(232, 55)
        ..lineTo(244, 84),
      pen,
    );
    for (final x in [82.0, 257.0]) {
      canvas.drawCircle(Offset(x, 95), 22, Paint()..color = _navy);
      canvas.drawCircle(Offset(x, 95), 22, pen);
      canvas.drawCircle(Offset(x, 95), 12, pen);
    }
    canvas.drawLine(
      const Offset(8, 119),
      const Offset(332, 119),
      Paint()
        ..color = _aqua.withValues(alpha: .55)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_VehicleOutline oldDelegate) => false;
}
