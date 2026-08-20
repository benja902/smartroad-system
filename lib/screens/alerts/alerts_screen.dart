import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_time_formatting.dart';
import '../../models/accident_level.dart';
import '../../models/event_status.dart';
import '../../navigation/app_router.dart';
import '../../state/device_status_provider.dart';
import '../../state/event_provider.dart';
import 'widgets/active_alerts_section.dart';
import 'widgets/informative_events_section.dart';
import 'widgets/recent_history_section.dart';
import 'widgets/technical_status_section.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;
    final deviceStatus = context.watch<DeviceStatusProvider>().status;

    final activeAlerts = events.where((e) => e.isActiveCritical).toList();
    final informativeEvents = events.where((e) => e.level == AccidentLevel.level1).toList();
    final resolvedEvents = events
        .where((e) => e.status == EventStatus.closed || e.status == EventStatus.cancelled)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.edgeMargin,
                    AppSpacing.xs,
                    AppSpacing.edgeMargin,
                    AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TitleRow(lastUpdate: deviceStatus?.lastSeen),
                      const SizedBox(height: AppSpacing.md),
                      ActiveAlertsSection(
                        activeAlerts: activeAlerts,
                        onViewDetails: (event) => context.push('${AppRoutes.incidentDetail}/${event.id}'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InformativeEventsSection(events: informativeEvents),
                      const SizedBox(height: AppSpacing.md),
                      TechnicalStatusSection(status: deviceStatus),
                      const SizedBox(height: AppSpacing.md),
                      RecentHistorySection(resolvedEvents: resolvedEvents),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edgeMargin, vertical: AppSpacing.base),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.onSurfaceVariant),
          Text('URBES', style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
          const Icon(Icons.sensors, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final DateTime? lastUpdate;

  const _TitleRow({this.lastUpdate});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Alertas', style: AppTypography.displayLgMobile.copyWith(color: AppColors.primary)),
        if (lastUpdate != null)
          Text(
            'Actualizado ${formatRelativeTime(lastUpdate!)}',
            style: AppTypography.labelSm.copyWith(color: AppColors.outline),
          ),
      ],
    );
  }
}
