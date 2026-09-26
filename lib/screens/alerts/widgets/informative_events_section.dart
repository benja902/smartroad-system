import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_time_formatting.dart';
import '../../../models/accident_event.dart';
import '../../../models/accident_event_type.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_pill.dart';
import 'alert_card.dart';

/// crash/rollover events classified as informative (severity leve, or
/// none/unknown) — never interrupts navigation.
class InformativeEventsSection extends StatelessWidget {
  final List<AccidentEvent> events;

  const InformativeEventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'Eventos informativos'),
        const SizedBox(height: AppSpacing.sm),
        if (events.isEmpty)
          Text(
            'Sin eventos informativos recientes.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          )
        else
          Column(
            children: [
              for (final event in events) ...[
                _InformativeEventCard(event: event),
                if (event != events.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _InformativeEventCard extends StatelessWidget {
  final AccidentEvent event;

  const _InformativeEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final locationLabel = event.position?.fix == true
        ? '${event.position!.latitude.toStringAsFixed(4)}, ${event.position!.longitude.toStringAsFixed(4)}'
        : null;
    final title = event.type == AccidentEventType.rollover ? 'Evento de vuelco leve' : 'Evento leve detectado';

    return AlertCard(
      accentColor: AppColors.outlineVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: const Icon(Icons.info, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('Se registró un movimiento o impacto menor en el vehículo.',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const StatusPill(label: 'Leve', color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.sm,
            children: [
              Text(
                [formatRelativeTime(event.ts ?? event.receivedAt), ?locationLabel].join(' • '),
                style: AppTypography.labelSm.copyWith(color: AppColors.outline),
              ),
              Text('Sin acción requerida',
                  style: AppTypography.labelSm.copyWith(color: AppColors.outline, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
