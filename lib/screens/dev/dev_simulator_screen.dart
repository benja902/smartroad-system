import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/device_repository.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/mock/mock_device_repository.dart';
import '../../repositories/mock/mock_event_repository.dart';
import '../../state/device_status_provider.dart';
import '../../state/event_provider.dart';

/// Development-only panel to demonstrate the whole system without
/// hardware. Only reachable from main_dev.dart (never main.dart). Casts
/// the injected repositories to their concrete Mock types to call
/// simulator-only methods that intentionally aren't on the production
/// repository interfaces.
class DevSimulatorScreen extends StatelessWidget {
  const DevSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceRepo = context.read<DeviceRepository>() as MockDeviceRepository;
    final eventRepo = context.read<EventRepository>() as MockEventRepository;
    final status = context.watch<DeviceStatusProvider>().status;
    final criticalEvent = context.watch<EventProvider>().criticalEvent;
    final events = context.watch<EventProvider>().events;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de desarrollo')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.edgeMargin),
              children: [
                Text(
                  'Simula el hardware y los eventos de accidente sin necesidad de un ESP32 conectado.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Sistema y conectividad',
                  children: [
                    _StatusSwitch(
                      label: 'Sistema operativo',
                      value: status?.online == true && status?.monitoring == true,
                      onChanged: deviceRepo.setSystemOperational,
                    ),
                    _StatusSwitch(
                      label: 'Dispositivo offline',
                      value: status?.online == false,
                      onChanged: deviceRepo.setDeviceOffline,
                    ),
                    _StatusSwitch(
                      label: 'Red celular offline',
                      value: status?.cellularConnected == false,
                      onChanged: deviceRepo.setCellularOffline,
                    ),
                    _StatusSwitch(
                      label: 'GNSS offline',
                      value: status?.gnssAvailable == false,
                      onChanged: deviceRepo.setGnssOffline,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Sensores',
                  children: [
                    _StatusSwitch(
                      label: 'ADXL375 offline',
                      value: status?.adxl375Connected == false,
                      onChanged: deviceRepo.setAdxl375Offline,
                    ),
                    _StatusSwitch(
                      label: 'LSM6DS3 offline',
                      value: status?.lsm6ds3Connected == false,
                      onChanged: deviceRepo.setLsm6ds3Offline,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Disparar accidente',
                  children: [
                    _ActionButton(label: 'Simular Nivel 1', onPressed: eventRepo.triggerLevel1),
                    _ActionButton(label: 'Simular Nivel 2', onPressed: eventRepo.triggerLevel2),
                    _ActionButton(label: 'Simular Nivel 3', onPressed: eventRepo.triggerLevel3),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Evento crítico actual',
                  children: [
                    Text(
                      criticalEvent == null
                          ? 'No hay ningún evento crítico activo.'
                          : '${criticalEvent.level.name} • ${criticalEvent.status.name} • id: ${criticalEvent.id}',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActionButton(
                      label: 'Confirmar Nivel 2 ("Necesito ayuda")',
                      onPressed: criticalEvent == null ? null : () => eventRepo.confirmEmergency(criticalEvent.id),
                    ),
                    _ActionButton(
                      label: 'Cancelar alerta Nivel 2',
                      onPressed: criticalEvent == null ? null : () => eventRepo.cancelAlert(criticalEvent.id),
                    ),
                    _ActionButton(
                      label: 'Cerrar incidente',
                      onPressed: criticalEvent == null ? null : () => eventRepo.closeIncident(criticalEvent.id),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Eventos registrados (${events.length})',
                  children: [
                    if (events.isEmpty)
                      Text('Sin eventos todavía.', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant))
                    else
                      for (final event in events.reversed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${event.level.name} • ${event.status.name} • ${event.id}',
                            style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.headlineMd.copyWith(fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.xs),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StatusSwitch({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTypography.bodyMd),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(label),
        ),
      ),
    );
  }
}
