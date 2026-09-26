import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/alert_presentation.dart';
import '../../../widgets/section_header.dart';

/// Resolved/deferred events: cancelled by the device, acknowledged by the
/// user, or arrived late from the offline queue — most recent first.
class RecentHistorySection extends StatelessWidget {
  final List<AccidentEvent> events;

  const RecentHistorySection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final recent = events.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'Historial reciente'),
        const SizedBox(height: AppSpacing.sm),
        if (recent.isEmpty)
          Text(
            'Sin historial reciente.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          )
        else
          Column(
            children: [
              for (final event in recent) ...[
                _HistoryRow(event: event),
                if (event != recent.last) const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final AccidentEvent event;

  const _HistoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final presentation = classify(event);

    final IconData icon;
    final Color color;
    final String title;
    final String subtitle;

    switch (presentation) {
      case AlertPresentation.cancelled:
        icon = Icons.cancel;
        color = AppColors.onSurfaceVariant;
        title = 'Alerta cancelada';
        subtitle = 'Anulada desde el equipo.';
      case AlertPresentation.attended:
        icon = Icons.check_circle;
        color = AppColors.success;
        title = 'Incidente atendido';
        subtitle = 'Marcado como visto en la app.';
      case AlertPresentation.deferred:
        icon = Icons.schedule;
        color = AppColors.warning;
        title = 'Evento recibido con retraso';
        subtitle = 'Ocurrió antes de que el equipo recuperara conexión.';
      default:
        icon = Icons.info_outline;
        color = AppColors.onSurfaceVariant;
        title = 'Evento registrado';
        subtitle = '';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.chipBackground(color), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
              ],
            ),
          ),
          Text(
            formatRelativeTime(event.ts ?? event.receivedAt),
            style: AppTypography.labelSm.copyWith(color: AppColors.outlineVariant),
          ),
        ],
      ),
    );
  }
}
