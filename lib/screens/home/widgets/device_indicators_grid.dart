import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/device_status.dart';

/// 2x2 grid of quick device indicators: connectivity, network, GNSS, last
/// communication. Uses Wrap so it reflows cleanly on narrow screens instead
/// of relying on a fixed-width grid.
class DeviceIndicatorsGrid extends StatelessWidget {
  final DeviceStatus status;

  const DeviceIndicatorsGrid({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cellularOk = status.modem?.registered == true;
    final gnssOk = status.gnss?.fix == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: tileWidth,
              child: _IndicatorTile(
                icon: Icons.router_outlined,
                label: status.online ? 'Dispositivo conectado' : 'Dispositivo desconectado',
                ok: status.online,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _IndicatorTile(
                icon: Icons.signal_cellular_alt,
                label: cellularOk ? (status.modem?.tech ?? 'Celular conectado') : 'Sin conexión celular',
                ok: cellularOk,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _IndicatorTile(
                icon: Icons.satellite_alt_outlined,
                label: gnssOk ? 'GNSS disponible' : 'GNSS no disponible',
                ok: gnssOk,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _IndicatorTile(
                icon: Icons.update,
                label: 'Última com: ${formatRelativeTime(status.lastSeen)}',
                ok: status.online,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ok;

  const _IndicatorTile({required this.icon, required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelSm.copyWith(color: AppColors.primary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
