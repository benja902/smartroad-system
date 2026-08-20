import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/accident_event.dart';
import '../../models/device_status.dart';
import '../../models/event_status.dart';
import '../../navigation/app_router.dart';
import '../../state/device_status_provider.dart';
import '../../state/event_provider.dart';
import '../../widgets/critical_button.dart';
import '../../widgets/ghost_button.dart';
import '../../widgets/status_pill.dart';
import 'widgets/countdown_ring.dart';
import 'widgets/emergency_status_card.dart';

/// Full-screen critical flow — no BottomNavigationBar. Handles both the
/// pendingConfirmation countdown and, after confirmation, the resulting
/// active-emergency state (level stays level2, status becomes
/// emergencyActive) without navigating away, since Nivel 2 never becomes
/// visually "coral critical" — that color is reserved for Nivel 3.
class Level2Screen extends StatelessWidget {
  const Level2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>().criticalEvent;
    final deviceStatus = context.watch<DeviceStatusProvider>().status;

    if (event == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edgeMargin, vertical: AppSpacing.lg),
              child: event.status == EventStatus.pendingConfirmation
                  ? _PendingConfirmationView(event: event, deviceStatus: deviceStatus)
                  : _EmergencyActiveView(event: event),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingConfirmationView extends StatelessWidget {
  final AccidentEvent event;
  final DeviceStatus? deviceStatus;

  const _PendingConfirmationView({required this.event, this.deviceStatus});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.read<EventProvider>();

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.chipBackground(AppColors.warning), shape: BoxShape.circle),
          child: const Icon(Icons.warning, color: AppColors.warning, size: 48),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'POSIBLE ACCIDENTE DETECTADO',
          textAlign: TextAlign.center,
          style: AppTypography.displayLgMobile.copyWith(color: AppColors.warning),
        ),
        const SizedBox(height: AppSpacing.base),
        const StatusPill(label: 'NIVEL 2', color: AppColors.warning),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Detectamos un impacto inusual en tu vehículo.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        CountdownRing(
          startedAt: event.detectedAt,
          deadline: event.deadline ?? event.detectedAt.add(const Duration(seconds: 15)),
          onExpired: () => eventProvider.confirmEmergency(event.id),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'La alerta se enviará automáticamente al finalizar la cuenta regresiva.',
          textAlign: TextAlign.center,
          style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        EmergencyStatusCard(
          icon: Icons.save_alt,
          title: 'Preparando alerta',
          subtitle: 'Obteniendo ubicación y preparando los datos de emergencia.',
          accentColor: AppColors.warning,
          chips: [
            StatusChip(
              icon: Icons.satellite_alt,
              label: (deviceStatus?.gnssAvailable ?? false) ? 'GNSS disponible' : 'GNSS no disponible',
            ),
            if (event.location != null) const StatusChip(icon: Icons.location_on, label: 'Ubicación obtenida'),
            StatusChip(icon: Icons.group, label: '${event.contactsNotified} contactos preparados'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        CriticalButton(
          label: 'Necesito ayuda ahora',
          icon: Icons.emergency,
          color: AppColors.warningStrong,
          onPressed: () => eventProvider.confirmEmergency(event.id),
        ),
        const SizedBox(height: AppSpacing.sm),
        GhostButton(
          label: 'Cancelar alerta',
          onPressed: () => eventProvider.cancelAlert(event.id),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Solo si estás seguro de que fue una falsa alarma.',
          textAlign: TextAlign.center,
          style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmergencyActiveView extends StatelessWidget {
  final AccidentEvent event;

  const _EmergencyActiveView({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.chipBackground(AppColors.warning), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, color: AppColors.warning, size: 48),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'EMERGENCIA EN CURSO',
          textAlign: TextAlign.center,
          style: AppTypography.displayLgMobile.copyWith(color: AppColors.warning),
        ),
        const SizedBox(height: AppSpacing.base),
        const StatusPill(label: 'NIVEL 2', color: AppColors.warning),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tu alerta fue enviada. Un equipo está al tanto de tu situación.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        EmergencyStatusCard(
          icon: Icons.check,
          title: 'Alerta enviada',
          subtitle: 'La emergencia continúa activa mientras se resuelve el incidente.',
          accentColor: AppColors.warning,
          chips: [
            StatusChip(icon: Icons.group, label: '${event.contactsNotified} contactos notificados'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => context.push('${AppRoutes.incidentDetail}/${event.id}'),
          child: const Text('Ver incidente'),
        ),
        const SizedBox(height: AppSpacing.sm),
        CriticalButton(
          label: 'Llamar a emergencias',
          icon: Icons.call,
          color: AppColors.warningStrong,
          onPressed: () {},
        ),
      ],
    );
  }
}
