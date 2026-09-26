import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/accident_event_type.dart';
import '../../../models/device_status.dart';
import '../../../widgets/section_header.dart';
import 'alert_card.dart';

class _TechnicalIssue {
  final IconData icon;
  final String title;
  final String description;

  const _TechnicalIssue({required this.icon, required this.title, required this.description});
}

/// Current diagnostic status derived from DeviceStatus, plus technical
/// events (test/power_loss/low_battery/booted) — never mixed with the
/// accident feed.
class TechnicalStatusSection extends StatelessWidget {
  final DeviceStatus? status;
  final List<AccidentEvent> technicalEvents;

  const TechnicalStatusSection({super.key, this.status, this.technicalEvents = const []});

  List<_TechnicalIssue> _issuesFor(DeviceStatus status) {
    final issues = <_TechnicalIssue>[];
    if (status.modem?.registered != true) {
      issues.add(const _TechnicalIssue(
        icon: Icons.signal_cellular_off,
        title: 'Sin red celular',
        description: 'El equipo no está registrado en la red móvil en este momento.',
      ));
    }
    if (status.gnss?.fix != true) {
      issues.add(const _TechnicalIssue(
        icon: Icons.gps_off,
        title: 'GNSS sin señal',
        description: 'La ubicación puede no actualizarse hasta recuperar señal satelital.',
      ));
    }
    if (status.adxl375?.ok == false || status.lsm6ds3?.ok == false) {
      issues.add(const _TechnicalIssue(
        icon: Icons.sensors_off,
        title: 'Sensor de impacto desconectado',
        description: 'Uno de los sensores de detección no está respondiendo.',
      ));
    }
    if (status.pcf8574?.ok == false) {
      issues.add(const _TechnicalIssue(
        icon: Icons.power_off,
        title: 'Expansor de botones/LED desconectado',
        description: 'Sin él no funcionan los botones SOS/CANCELAR, los LED ni el buzzer.',
      ));
    }
    if (status.storage?.present == false) {
      issues.add(const _TechnicalIssue(
        icon: Icons.sd_card_alert,
        title: 'microSD ausente',
        description: 'La cola de reenvío pasa a memoria volátil y se pierde el registro histórico.',
      ));
    }
    if (!status.online) {
      issues.add(const _TechnicalIssue(
        icon: Icons.wifi_off,
        title: 'Dispositivo desconectado',
        description: 'No se reciben datos del equipo en este momento.',
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
        if (technicalEvents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final event in technicalEvents) _TechnicalEventRow(event: event),
        ],
      ],
    );
  }
}

class _TechnicalEventRow extends StatelessWidget {
  final AccidentEvent event;

  const _TechnicalEventRow({required this.event});

  String get _label {
    switch (event.type) {
      case AccidentEventType.test:
        return 'Prueba de sistema ejecutada';
      case AccidentEventType.powerLoss:
        return 'Pérdida de alimentación externa';
      case AccidentEventType.lowBattery:
        return 'Batería baja detectada';
      case AccidentEventType.booted:
        return 'El equipo se reinició';
      default:
        return 'Evento técnico';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.build_outlined, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(_label, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface))),
          Text(formatRelativeTime(event.ts ?? event.receivedAt), style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
        ],
      ),
    );
  }
}
