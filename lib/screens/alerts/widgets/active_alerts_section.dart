import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/accident_level.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_pill.dart';
import 'alert_card.dart';

/// Level2/3 events that are still unresolved — the most urgent section.
class ActiveAlertsSection extends StatelessWidget {
  final List<AccidentEvent> activeAlerts;
  final void Function(AccidentEvent event) onViewDetails;

  const ActiveAlertsSection({super.key, required this.activeAlerts, required this.onViewDetails});

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
                _ActiveAlertCard(event: event, onViewDetails: () => onViewDetails(event)),
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

  const _ActiveAlertCard({required this.event, required this.onViewDetails});

  Color get _color => event.level == AccidentLevel.level3 ? AppColors.critical : AppColors.warning;

  String get _title =>
      event.level == AccidentLevel.level3 ? 'Accidente severo detectado' : 'Posible accidente detectado';

  String get _description => event.level == AccidentLevel.level3
      ? 'Impacto de alta severidad registrado en el vehículo.'
      : 'Impacto inusual registrado en el vehículo.';

  @override
  Widget build(BuildContext context) {
    final levelLabel = event.level == AccidentLevel.level3 ? 'Nivel 3' : 'Nivel 2';
    final locationLabel = event.location?.displayName;

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
              StatusPill(label: levelLabel, color: _color),
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
                [formatRelativeTime(event.detectedAt), ?locationLabel].join(' • '),
                style: AppTypography.labelSm.copyWith(color: AppColors.outline),
              ),
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
    );
  }
}
