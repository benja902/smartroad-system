import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_pill.dart';

class VehicleSummaryCard extends StatelessWidget {
  final VehicleModel? vehicle;
  final bool deviceConnected;

  const VehicleSummaryCard({super.key, required this.vehicle, required this.deviceConnected});

  @override
  Widget build(BuildContext context) {
    final vehicle = this.vehicle;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(label: 'Vehículo principal'),
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      vehicle == null
                          ? 'Sin vehículo configurado'
                          : '${vehicle.brand} ${vehicle.model} • Placa: ${vehicle.plate}',
                      style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.directions_car, color: AppColors.primary),
              ),
            ],
          ),
          if (vehicle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            StatusPill(
              label: deviceConnected ? 'Dispositivo URBES conectado' : 'Dispositivo URBES desconectado',
              color: deviceConnected ? AppColors.success : AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }
}
