import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Shared card shell for Alertas rows: white card, 24px radius, soft
/// shadow, colored top-border accent indicating severity.
class AlertCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const AlertCard({super.key, required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: Border(top: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), offset: const Offset(0, 4), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }
}
