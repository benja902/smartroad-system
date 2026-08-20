import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/event_status.dart';
import '../../../widgets/section_header.dart';

/// Resolved events (closed or cancelled), most recent first.
class RecentHistorySection extends StatelessWidget {
  final List<AccidentEvent> resolvedEvents;

  const RecentHistorySection({super.key, required this.resolvedEvents});

  @override
  Widget build(BuildContext context) {
    final recent = resolvedEvents.reversed.take(5).toList();

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

  bool get _isCancelled => event.status == EventStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final icon = _isCancelled ? Icons.cancel : Icons.check_circle;
    final color = _isCancelled ? AppColors.onSurfaceVariant : AppColors.success;
    final title = _isCancelled ? 'Alerta cancelada' : 'Incidente cerrado';
    final subtitle =
        _isCancelled ? 'El usuario indicó falsa alarma.' : 'La alerta fue gestionada correctamente.';

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
                Text(subtitle, style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
              ],
            ),
          ),
          Text(formatRelativeTime(event.detectedAt), style: AppTypography.labelSm.copyWith(color: AppColors.outlineVariant)),
        ],
      ),
    );
  }
}
