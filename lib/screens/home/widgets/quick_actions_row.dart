import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const QuickAction({required this.icon, required this.label, required this.subtitle, required this.onTap});
}

/// Row of quick-access actions. Uses Expanded so each tile shares the
/// available width evenly regardless of screen size, instead of a fixed
/// column width.
class QuickActionsRow extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _QuickActionTile(action: actions[i])),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: Icon(action.icon, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
