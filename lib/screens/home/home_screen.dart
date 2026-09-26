import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/alert_presentation.dart';
import '../../navigation/app_router.dart';
import '../../state/device_status_provider.dart';
import '../../state/event_provider.dart';
import '../../state/session_provider.dart';
import '../../state/vehicle_provider.dart';
import '../../widgets/attention_banner.dart';
import 'widgets/device_indicators_grid.dart';
import 'widgets/location_map_placeholder.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/recent_alerts_preview.dart';
import 'widgets/urbes_status_card.dart';
import 'widgets/vehicle_summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user;
    final deviceStatus = context.watch<DeviceStatusProvider>().status;
    final events = context.watch<EventProvider>().events;
    final vehicle = context.watch<VehicleProvider>().vehicle;
    final eventProvider = context.read<EventProvider>();

    final attentionEvents = events.where((e) => classify(e) == AlertPresentation.attention).toList();
    final topAttentionEvent = attentionEvents.isEmpty ? null : attentionEvents.last;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(monitoring: deviceStatus?.online ?? false)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.edgeMargin,
                    AppSpacing.sm,
                    AppSpacing.edgeMargin,
                    AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _WelcomeSection(userName: user?.name ?? 'Usuario'),
                      const SizedBox(height: AppSpacing.md),
                      UrbesStatusCard(
                        operational: deviceStatus?.online ?? false,
                        monitoring: deviceStatus?.online ?? false,
                      ),
                      if (topAttentionEvent != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        AttentionBanner(
                          event: topAttentionEvent,
                          onAcknowledge: () => eventProvider.acknowledge(topAttentionEvent.dedupKey),
                          onViewDetails: () => context.push('${AppRoutes.incidentDetail}/${topAttentionEvent.dedupKey}'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      if (deviceStatus != null) DeviceIndicatorsGrid(status: deviceStatus),
                      const SizedBox(height: AppSpacing.md),
                      VehicleSummaryCard(
                        vehicle: vehicle,
                        deviceConnected: deviceStatus?.online ?? false,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LocationMapPlaceholder(
                        position: deviceStatus?.gnss,
                        onViewMap: () {},
                      ),
                      const SizedBox(height: AppSpacing.md),
                      QuickActionsRow(
                        actions: [
                          QuickAction(
                            icon: Icons.group_outlined,
                            label: 'Contactos de emergencia',
                            subtitle: 'Gestionar',
                            onTap: () => context.push(AppRoutes.contacts),
                          ),
                          QuickAction(
                            icon: Icons.history_outlined,
                            label: 'Historial',
                            subtitle: 'Ver viajes',
                            onTap: () => context.go(AppRoutes.history),
                          ),
                          QuickAction(
                            icon: Icons.directions_car_outlined,
                            label: 'Vehículo',
                            subtitle: 'Detalles',
                            onTap: () => context.go(AppRoutes.vehicle),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      RecentAlertsPreview(events: events),
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
  final bool monitoring;

  const _Header({required this.monitoring});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edgeMargin, vertical: AppSpacing.base),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.onSurfaceVariant),
          Text('URBES', style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.sensors, color: AppColors.onSurfaceVariant),
              if (monitoring)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final String userName;

  const _WelcomeSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${userName.split(' ').first}',
                style: AppTypography.displayLgMobile.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Tu sistema URBES está funcionando correctamente',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.person, color: AppColors.onPrimary),
        ),
      ],
    );
  }
}
