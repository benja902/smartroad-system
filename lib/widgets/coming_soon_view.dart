import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Shared body for placeholder screens/modules that don't have a Stitch
/// design yet (Vehículo, Historial, Perfil, Login, Registro, Contactos,
/// Detalle de incidente). Responsive: scrolls instead of overflowing on
/// small screens, caps width on large ones.
class ComingSoonView extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonView({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.edgeMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: AppColors.outline),
                const SizedBox(height: AppSpacing.sm),
                Text(title, style: AppTypography.headlineMd, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Próximamente',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
