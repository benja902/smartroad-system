import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/accident_event.dart';
import '../../models/accident_event_type.dart';
import '../../models/modem_status.dart';
import '../../navigation/app_router.dart';
import '../../navigation/dev_mode_flag.dart';
import '../../navigation/dev_navigation_override.dart';
import '../../state/event_provider.dart';
import '../../state/vehicle_provider.dart';
import '../../widgets/critical_button.dart';
import '../../widgets/status_pill.dart';

/// Full-screen critical flow — no BottomNavigationBar. Reached whenever
/// shouldForceCriticalScreen() is true for the current critical event:
/// a live (non-queued, non-cancelled, non-acknowledged) crash/rollover
/// with severity grave, or an sos. There is no countdown here — the
/// device's own grace period happens locally and is never visible to
/// Firebase (see docs/device_contract.md); by the time this screen shows,
/// the alert has already been sent.
class ActiveEmergencyScreen extends StatelessWidget {
  const ActiveEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>().criticalEvent;
    final vehicle = context.watch<VehicleProvider>().vehicle;

    if (event == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edgeMargin, vertical: AppSpacing.lg),
                    child: _Content(event: event, vehicleLabel: vehicle?.plate ?? event.vehicleLabel),
                  ),
                ),
                _BottomActions(event: event),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final AccidentEvent event;
  final String? vehicleLabel;

  const _Content({required this.event, this.vehicleLabel});

  bool get _isSos => event.type == AccidentEventType.sos;

  IconData get _icon {
    if (_isSos) return Icons.emergency_share;
    if (event.type == AccidentEventType.rollover) return Icons.change_circle;
    return Icons.car_crash;
  }

  String get _title {
    if (_isSos) return 'AUXILIO SOLICITADO';
    if (event.type == AccidentEventType.rollover) return 'VOLCADURA DETECTADA';
    return 'CHOQUE SEVERO DETECTADO';
  }

  String get _subtitle {
    if (_isSos) return 'El ocupante solicitó ayuda manualmente desde el equipo.';
    return 'El equipo activó automáticamente el protocolo de emergencia.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.chipBackground(AppColors.critical), shape: BoxShape.circle),
          child: Icon(_icon, color: AppColors.critical, size: 48),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(_title, textAlign: TextAlign.center, style: AppTypography.displayLgMobile.copyWith(color: AppColors.onSurface)),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.base,
          children: [
            Text('ALERTA DE EMERGENCIA', style: AppTypography.labelSm.copyWith(color: AppColors.critical)),
            StatusPill(label: _isSos ? 'SOS' : 'GRAVE', color: AppColors.critical),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(_subtitle, textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.md),
        _EmergencyBanner(),
        const SizedBox(height: AppSpacing.sm),
        _LocationCard(event: event),
        const SizedBox(height: AppSpacing.sm),
        _InfoTile(
          icon: Icons.directions_car,
          label: 'VEHÍCULO',
          value: vehicleLabel ?? 'No disponible',
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _InfoTile(label: 'HORA', value: _formatTime(event))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _InfoTile(label: 'ORIGEN', value: 'Detección automática')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DiagnosticsCard(event: event),
      ],
    );
  }

  String _formatTime(AccidentEvent event) {
    final ts = event.ts;
    if (ts == null) return 'Hora no disponible';
    final hour = ts.hour.toString().padLeft(2, '0');
    final minute = ts.minute.toString().padLeft(2, '0');
    final prefix = event.timeSrc == 'uptime' ? '~' : '';
    return '$prefix$hour:$minute';
  }
}

class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.chipBackground(AppColors.critical),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning, color: AppColors.critical),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EMERGENCIA ACTIVA',
                    style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.critical)),
                const SizedBox(height: 2),
                Text(
                  'Esta pantalla se cerrará automáticamente si la alerta se anula desde el equipo, o si la marcas como atendida abajo.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final AccidentEvent event;

  const _LocationCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final position = event.position;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ubicación del incidente',
                          style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      Text(
                        position == null
                            ? 'El equipo nunca obtuvo posición GNSS'
                            : position.fix
                                ? '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'
                                : 'Última posición conocida (sin fix actual)',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      if (position != null && (position.fixAgeS ?? 0) > 60)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Ubicación de hace ${position.fixAgeS}s — puede no ser exacta',
                            style: AppTypography.labelSm.copyWith(color: AppColors.warning),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.location_on_outlined, color: AppColors.outline),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.surfaceDim,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: AppColors.chipBackground(AppColors.critical), shape: BoxShape.circle),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: AppColors.critical, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  final AccidentEvent event;

  const _DiagnosticsCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final device = event.device;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnóstico del equipo al momento del evento',
              style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          if (device == null)
            Text('Sin datos de diagnóstico para este evento.', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant))
          else ...[
            _diagnosticRow(Icons.battery_std, 'Batería',
                device.batteryV != null ? '${device.batteryV!.toStringAsFixed(2)} V' : 'No disponible'),
            _diagnosticRow(Icons.signal_cellular_alt, 'Señal',
                device.rssiDbm != null ? '${device.rssiDbm} dBm (${signalQualityLabel(device.rssiDbm)})' : 'No disponible'),
            _diagnosticRow(Icons.sd_storage_outlined, 'microSD', device.sd ? 'Presente' : 'Ausente'),
            if (device.degraded)
              _diagnosticRow(Icons.warning_amber, 'Estado', 'Evento generado con un sensor no disponible', color: AppColors.warning),
          ],
        ],
      ),
    );
  }

  Widget _diagnosticRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface))),
          Text(value, style: AppTypography.bodyMd.copyWith(color: color ?? AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _InfoTile({this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final AccidentEvent event;

  const _BottomActions({required this.event});

  @override
  Widget build(BuildContext context) {
    final devModeEnabled = context.watch<DevModeFlag>().enabled;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => context.push('${AppRoutes.incidentDetail}/${event.dedupKey}'),
            child: const Text('VER INCIDENTE'),
          ),
          const SizedBox(height: AppSpacing.xs),
          CriticalButton(
            label: 'LLAMAR A EMERGENCIAS',
            icon: Icons.call,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => context.read<EventProvider>().acknowledge(event.dedupKey),
            child: const Text('Ya lo vi — marcar como atendido'),
          ),
          if (devModeEnabled) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () {
                context.read<DevNavigationOverride>().eventKey = event.dedupKey;
                context.go(AppRoutes.dev);
              },
              icon: const Icon(Icons.build_outlined, size: 18),
              label: const Text('Volver a /dev'),
            ),
          ],
          Text(
            'La alerta permanecerá activa aunque cierres esta pantalla, salvo que se anule desde el equipo o la marques como atendida.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
