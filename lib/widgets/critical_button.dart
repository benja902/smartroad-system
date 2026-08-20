import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';

/// High-urgency action button. Defaults to red/coral, which per the design
/// system is strictly reserved for Nivel 3 ("ALERTA DE ACCIDENTE"). Nivel 2
/// screens must pass an amber-toned [color] instead — coral stays
/// exclusive to Nivel 3.
class CriticalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  const CriticalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.critical,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: AppColors.onPrimary,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
      textStyle: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700),
    );
    if (icon == null) {
      return ElevatedButton(style: style, onPressed: onPressed, child: Text(label));
    }
    return ElevatedButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
