import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// System status card: "URBES operativo" / "Monitoreo activo" with a
/// pulsing status dot, or a degraded state when the system isn't fully
/// operational.
class UrbesStatusCard extends StatelessWidget {
  final bool operational;
  final bool monitoring;

  const UrbesStatusCard({super.key, required this.operational, required this.monitoring});

  @override
  Widget build(BuildContext context) {
    final color = operational ? AppColors.success : AppColors.warning;
    final title = operational ? 'URBES operativo' : 'URBES con problemas';
    final subtitle = monitoring ? 'Monitoreo activo' : 'Monitoreo inactivo';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.chipBackground(color),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user, color: color, size: 28),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text(subtitle, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
