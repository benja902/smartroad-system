import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/accident_event_type.dart';
import '../../../models/alert_presentation.dart';

/// Preview of the most recent events on Home. Shows an all-clear row when
/// there is no event history yet.
class RecentAlertsPreview extends StatelessWidget {
  final List<AccidentEvent> events;
  final bool neutralEmpty;
  final bool editorial;
  final bool guardian;

  const RecentAlertsPreview({
    super.key,
    required this.events,
    this.neutralEmpty = false,
    this.editorial = false,
    this.guardian = false,
  });

  @override
  Widget build(BuildContext context) {
    final visible = events
        .where((e) => classify(e) != AlertPresentation.cancellation)
        .toList();
    final recent = visible.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          guardian ? 'Actividad reciente' : 'Alertas recientes',
          style: AppTypography.headlineMd.copyWith(
            color: guardian ? const Color(0xFF031B3B) : AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recent.isEmpty)
          _AlertRow(
            icon: neutralEmpty ? Icons.inbox_outlined : Icons.check_circle,
            iconColor: neutralEmpty
                ? AppColors.onSurfaceVariant
                : AppColors.success,
            title: neutralEmpty
                ? 'Sin registros para mostrar'
                : 'Sin incidentes recientes',
            subtitle: neutralEmpty
                ? 'Aquí aparecerán los registros recibidos.'
                : 'Todo en orden',
            emphasized: true,
            editorial: editorial,
            guardian: guardian,
          )
        else
          Column(
            children: [
              for (final event in recent) ...[
                _AlertRow(
                  icon: _iconFor(event),
                  iconColor: _colorFor(event),
                  title: _titleFor(event),
                  subtitle: formatRelativeTime(event.ts ?? event.receivedAt),
                  emphasized: const {
                    AlertPresentation.activeEmergency,
                    AlertPresentation.attention,
                  }.contains(classify(event)),
                  editorial: editorial,
                  guardian: guardian,
                ),
                if (event != recent.last)
                  const SizedBox(height: AppSpacing.gutter),
              ],
            ],
          ),
      ],
    );
  }

  IconData _iconFor(AccidentEvent event) {
    final presentation = classify(event);
    if (presentation == AlertPresentation.cancelled) {
      return Icons.cancel_outlined;
    }
    if (presentation == AlertPresentation.attended) {
      return guardian ? Icons.visibility_outlined : Icons.check_circle_outline;
    }
    if (presentation == AlertPresentation.technical) {
      return Icons.build_outlined;
    }
    switch (event.type) {
      case AccidentEventType.crash:
        if (guardian) return Icons.car_crash_outlined;
        return presentation == AlertPresentation.informative
            ? Icons.info_outline
            : Icons.warning_amber_outlined;
      case AccidentEventType.sos:
        return Icons.emergency_share;
      case AccidentEventType.rollover:
        return Icons.change_circle;
      default:
        return presentation == AlertPresentation.informative
            ? Icons.info_outline
            : Icons.warning_amber_outlined;
    }
  }

  Color _colorFor(AccidentEvent event) {
    switch (classify(event)) {
      case AlertPresentation.activeEmergency:
        return AppColors.critical;
      case AlertPresentation.attention:
        return AppColors.warning;
      case AlertPresentation.informative:
        return guardian ? const Color(0xFF006D68) : AppColors.success;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _titleFor(AccidentEvent event) {
    switch (event.type) {
      case AccidentEventType.sos:
        return 'Auxilio solicitado (SOS)';
      case AccidentEventType.rollover:
        return 'Volcadura detectada';
      case AccidentEventType.crash:
        return 'Impacto detectado';
      case AccidentEventType.test:
        return 'Prueba de sistema';
      case AccidentEventType.powerLoss:
        return 'Pérdida de alimentación';
      case AccidentEventType.lowBattery:
        return 'Batería baja';
      case AccidentEventType.booted:
        return 'Equipo reiniciado';
      default:
        return 'Evento del sistema';
    }
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool emphasized;
  final bool editorial;
  final bool guardian;

  const _AlertRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.emphasized,
    this.editorial = false,
    this.guardian = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: editorial
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E6EB))),
            )
          : emphasized
          ? BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.card,
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.chipBackground(iconColor),
              shape: guardian ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: guardian ? BorderRadius.circular(12) : null,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: guardian
                        ? const Color(0xFF031B3B)
                        : AppColors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
