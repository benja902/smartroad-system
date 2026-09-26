import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_time_formatting.dart';
import '../../models/alert_presentation.dart';
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
    final eventProvider = context.read<EventProvider>();

    final activeAlerts = events
        .where((e) => const {AlertPresentation.activeEmergency, AlertPresentation.attention}.contains(classify(e)))
        .toList();
    final informativeEvents = events.where((e) => classify(e) == AlertPresentation.informative).toList();
    final technicalEvents = events.where((e) => classify(e) == AlertPresentation.technical).toList();
    final historyEvents = events
        .where((e) => const {
              AlertPresentation.cancelled,
              AlertPresentation.attended,
              AlertPresentation.deferred,
            }.contains(classify(e)))
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
                        onViewDetails: (event) => context.push('${AppRoutes.incidentDetail}/${event.dedupKey}'),
                        onAcknowledge: (event) => eventProvider.acknowledge(event.dedupKey),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InformativeEventsSection(events: informativeEvents),
                      const SizedBox(height: AppSpacing.md),
                      TechnicalStatusSection(status: deviceStatus, technicalEvents: technicalEvents),
                      const SizedBox(height: AppSpacing.md),
                      RecentHistorySection(events: historyEvents),
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
