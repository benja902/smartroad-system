import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/accident_level.dart';
import '../../../models/event_status.dart';

/// Preview of the most recent events on Home. Shows an all-clear row when
/// there is no event history yet.
class RecentAlertsPreview extends StatelessWidget {
  final List<AccidentEvent> events;

  const RecentAlertsPreview({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final recent = events.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas recientes', style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        if (recent.isEmpty)
          const _AlertRow(
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            title: 'Sin incidentes recientes',
            subtitle: 'Todo en orden',
            emphasized: true,
          )
        else
          Column(
            children: [
              for (final event in recent) ...[
                _AlertRow(
                  icon: _iconFor(event),
                  iconColor: _colorFor(event),
                  title: _titleFor(event),
                  subtitle: formatRelativeTime(event.detectedAt),
                  emphasized: event.isActiveCritical,
                ),
                if (event != recent.last) const SizedBox(height: AppSpacing.gutter),
              ],
            ],
          ),
      ],
    );
  }

  IconData _iconFor(AccidentEvent event) {
    if (event.status == EventStatus.cancelled) return Icons.cancel_outlined;
    if (event.status == EventStatus.closed) return Icons.check_circle_outline;
    switch (event.level) {
      case AccidentLevel.level1:
        return Icons.info_outline;
      case AccidentLevel.level2:
        return Icons.warning_amber_outlined;
      case AccidentLevel.level3:
        return Icons.report;
    }
  }

  Color _colorFor(AccidentEvent event) {
    if (!event.isActiveCritical) return AppColors.onSurfaceVariant;
    switch (event.level) {
      case AccidentLevel.level1:
        return AppColors.success;
      case AccidentLevel.level2:
        return AppColors.warning;
      case AccidentLevel.level3:
        return AppColors.critical;
    }
  }

  String _titleFor(AccidentEvent event) {
    switch (event.level) {
      case AccidentLevel.level1:
        return 'Evento informativo detectado';
      case AccidentLevel.level2:
        return 'Posible accidente — Nivel 2';
      case AccidentLevel.level3:
        return 'Accidente severo — Nivel 3';
    }
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool emphasized;

  const _AlertRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: emphasized
          ? BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.card,
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.chipBackground(iconColor), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                Text(subtitle, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
