import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/accident_event.dart';
import '../../navigation/app_router.dart';
import '../../state/event_provider.dart';
import '../../state/vehicle_provider.dart';
import '../../widgets/critical_button.dart';
import '../../widgets/status_pill.dart';

/// Full-screen critical flow — no BottomNavigationBar, no countdown, no
/// cancel option. Reached immediately on Nivel 3 detection.
class Level3Screen extends StatelessWidget {
  const Level3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>().criticalEvent;

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
                    child: _Level3Content(event: event),
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

class _Level3Content extends StatelessWidget {
  final AccidentEvent event;

  const _Level3Content({required this.event});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>().vehicle;

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.chipBackground(AppColors.critical), shape: BoxShape.circle),
          child: const Icon(Icons.car_crash, color: AppColors.critical, size: 48),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'ACCIDENTE SEVERO DETECTADO',
          textAlign: TextAlign.center,
          style: AppTypography.displayLgMobile.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.base,
          children: [
            Text('ALERTA DE ACCIDENTE', style: AppTypography.labelSm.copyWith(color: AppColors.critical)),
            const StatusPill(label: 'NIVEL 3', color: AppColors.critical),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'URBES activó automáticamente el protocolo de emergencia.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
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
                    Text('La alerta fue enviada automáticamente y el incidente continúa activo.',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LocationCard(event: event),
        const SizedBox(height: AppSpacing.sm),
        _InfoTile(
          icon: Icons.directions_car,
          label: 'VEHÍCULO',
          value: vehicle == null ? 'Vehículo no disponible' : '${vehicle.brand} ${vehicle.model} · ${vehicle.plate}',
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _InfoTile(label: 'HORA', value: _formatTime(event.detectedAt)),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: _InfoTile(label: 'ORIGEN', value: 'Detección automática'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ProtocolStatusCard(event: event),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          children: [
            _FooterChannelChip(icon: Icons.signal_cellular_alt, label: 'Canal de envío: 4G'),
            const _FooterChannelChip(icon: Icons.satellite_alt, label: 'Respaldo satelital disponible'),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _LocationCard extends StatelessWidget {
  final AccidentEvent event;

  const _LocationCard({required this.event});

  @override
  Widget build(BuildContext context) {
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
                        '${event.location?.displayName ?? 'Ubicación no disponible'} | Ubicación compartida',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
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

class _ProtocolStatusCard extends StatelessWidget {
  final AccidentEvent event;

  const _ProtocolStatusCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Ubicación obtenida',
      'Alerta enviada',
      '${event.contactsNotified} contactos notificados',
    ];

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
          Text('Protocolo de emergencia',
              style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FooterChannelChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FooterChannelChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label.toUpperCase(), style: AppTypography.labelSm.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
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
            onPressed: () => context.push('${AppRoutes.incidentDetail}/${event.id}'),
            child: const Text('VER INCIDENTE'),
          ),
          const SizedBox(height: AppSpacing.xs),
          CriticalButton(
            label: 'LLAMAR A EMERGENCIAS',
            icon: Icons.call,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'La alerta permanecerá activa aunque cierres esta pantalla. URBES continuará actualizando el estado del incidente automáticamente.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
