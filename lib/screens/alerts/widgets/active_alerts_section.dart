import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/accident_event_type.dart';
import '../../../models/alert_presentation.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_pill.dart';
import 'alert_card.dart';

/// Events currently classified as activeEmergency or attention — the most
/// urgent, unresolved section.
class ActiveAlertsSection extends StatelessWidget {
  final List<AccidentEvent> activeAlerts;
  final void Function(AccidentEvent event) onViewDetails;
  final void Function(AccidentEvent event) onAcknowledge;

  const ActiveAlertsSection({
    super.key,
    required this.activeAlerts,
    required this.onViewDetails,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'Alertas activas'),
        const SizedBox(height: AppSpacing.sm),
        if (activeAlerts.isEmpty)
          Text(
            'Sin alertas activas en este momento.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          )
        else
          Column(
            children: [
              for (final event in activeAlerts) ...[
                _ActiveAlertCard(
                  event: event,
                  onViewDetails: () => onViewDetails(event),
                  onAcknowledge: () => onAcknowledge(event),
                ),
                if (event != activeAlerts.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _ActiveAlertCard extends StatelessWidget {
  final AccidentEvent event;
  final VoidCallback onViewDetails;
  final VoidCallback onAcknowledge;

  const _ActiveAlertCard({required this.event, required this.onViewDetails, required this.onAcknowledge});

  bool get _isEmergency => classify(event) == AlertPresentation.activeEmergency;

  Color get _color => _isEmergency ? AppColors.critical : AppColors.warning;

  String get _title {
    if (event.type == AccidentEventType.sos) return 'Auxilio solicitado (SOS)';
    if (event.type == AccidentEventType.rollover) return _isEmergency ? 'Volcadura detectada' : 'Posible volcadura';
    return _isEmergency ? 'Choque severo detectado' : 'Posible accidente detectado';
  }

  String get _description {
    final peakG = event.detection?.peakG;
    if (event.type == AccidentEventType.sos) return 'El ocupante solicitó ayuda manualmente.';
    if (peakG != null) return 'Impacto registrado: ${peakG.toStringAsFixed(1)} g.';
    return 'Impacto inusual registrado en el vehículo.';
  }

  @override
  Widget build(BuildContext context) {
    final label = event.type == AccidentEventType.sos
        ? 'SOS'
        : _isEmergency
            ? 'Grave'
            : 'Moderado';
    final locationLabel = event.position?.fix == true
        ? '${event.position!.latitude.toStringAsFixed(4)}, ${event.position!.longitude.toStringAsFixed(4)}'
        : null;

    return AlertCard(
      accentColor: _color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.chipBackground(_color), shape: BoxShape.circle),
                child: Icon(Icons.warning, color: _color, size: 28),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(_description, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              StatusPill(label: label, color: _color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                [formatRelativeTime(event.ts ?? event.receivedAt), ?locationLabel].join(' • '),
                style: AppTypography.labelSm.copyWith(color: AppColors.outline),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: onAcknowledge, child: const Text('Ya lo vi')),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    ),
                    child: const Text('Ver Detalles'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
