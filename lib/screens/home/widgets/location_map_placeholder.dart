import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/location_model.dart';
import '../../../widgets/section_header.dart';

/// Map card. Renders a placeholder (no map SDK wired up yet) that keeps
/// the same visual language as the eventual real map: light surface,
/// centered pin, "mi ubicación" affordance. Uses AspectRatio instead of a
/// fixed pixel height so it scales with screen width.
class LocationMapPlaceholder extends StatelessWidget {
  final LocationModel? location;
  final VoidCallback? onViewMap;

  const LocationMapPlaceholder({super.key, this.location, this.onViewMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(label: 'Última ubicación'),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        location?.displayName ?? 'Ubicación no disponible',
                        style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onViewMap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver mapa', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.surfaceDim,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: const BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle),
                      child: const Icon(Icons.my_location, size: 20, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
