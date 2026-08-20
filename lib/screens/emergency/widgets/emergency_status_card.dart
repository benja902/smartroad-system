import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatusChip {
  final IconData icon;
  final String label;

  const StatusChip({required this.icon, required this.label});
}

/// Left-accented status card used by the emergency flows to show
/// "preparando alerta" / "alerta enviada" style progress plus a row of
/// small diagnostic chips (GNSS, ubicación, contactos).
class EmergencyStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<StatusChip> chips;

  const EmergencyStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.chips = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), offset: const Offset(0, 4), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(subtitle, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.base,
              children: [
                for (final chip in chips)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chip.icon, size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        chip.label.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
