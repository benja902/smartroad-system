import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/device_status.dart';
import '../../../widgets/section_header.dart';
import 'alert_card.dart';

class _TechnicalIssue {
  final IconData icon;
  final String title;
  final String description;

  const _TechnicalIssue({required this.icon, required this.title, required this.description});
}

/// Current technical/diagnostic status derived from DeviceStatus — not an
/// AccidentEvent. Shows active issues (e.g. cellular down, GNSS
/// unavailable) or an all-clear row when everything is connected.
class TechnicalStatusSection extends StatelessWidget {
  final DeviceStatus? status;

  const TechnicalStatusSection({super.key, this.status});

  List<_TechnicalIssue> _issuesFor(DeviceStatus status) {
    final issues = <_TechnicalIssue>[];
    if (!status.cellularConnected) {
      issues.add(const _TechnicalIssue(
        icon: Icons.satellite_alt,
        title: 'Conexión móvil no disponible',
        description: 'El sistema activó el canal de respaldo para mantener la comunicación.',
      ));
    }
    if (!status.gnssAvailable || !status.gnssFix) {
      issues.add(const _TechnicalIssue(
        icon: Icons.gps_off,
        title: 'GNSS sin señal',
        description: 'La ubicación puede no actualizarse hasta recuperar señal satelital.',
      ));
    }
    if (!status.adxl375Connected || !status.lsm6ds3Connected) {
      issues.add(const _TechnicalIssue(
        icon: Icons.sensors_off,
        title: 'Sensor de impacto desconectado',
        description: 'Uno de los sensores de detección no está respondiendo.',
      ));
    }
    if (!status.online) {
      issues.add(const _TechnicalIssue(
        icon: Icons.wifi_off,
        title: 'Dispositivo desconectado',
        description: 'No se reciben datos del dispositivo URBES en este momento.',
      ));
    }
    return issues;
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = status;
    final issues = currentStatus == null ? const <_TechnicalIssue>[] : _issuesFor(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'Estado técnico'),
        const SizedBox(height: AppSpacing.sm),
        if (issues.isEmpty)
          AlertCard(
            accentColor: AppColors.success,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.chipBackground(AppColors.success), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: AppColors.success),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Todo funcionando correctamente',
                          style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Text('Conectividad, GNSS y sensores operativos.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (final issue in issues) ...[
                AlertCard(
                  accentColor: AppColors.primary,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                        child: Icon(issue.icon, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(issue.title,
                                style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const SizedBox(height: 2),
                            Text(issue.description, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (issue != issues.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}
