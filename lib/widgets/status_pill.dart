import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Small rounded pill with a semantic-color background at 15% opacity and
/// full-strength text, e.g. "Operativo" (success), "Revisión requerida"
/// (warning), "Alerta" (critical).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.chipBackground(color),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.base),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
