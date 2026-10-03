import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/accident_event_type.dart';
import '../../models/accident_severity.dart';
import '../../models/alert_presentation.dart';
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
/// repository interfaces. Triggers mirror the real firmware taxonomy
/// (type + severity + queued), not an invented level system.
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
                  'Simula el hardware y los eventos del sistema SDA sin necesidad de un equipo conectado.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Sistema y conectividad',
                  children: [
                    _StatusSwitch(
                      label: 'Sistema operativo',
                      value: status?.online == true,
                      onChanged: deviceRepo.setSystemOperational,
                    ),
                    _StatusSwitch(
                      label: 'Dispositivo offline',
                      value: status?.online == false,
                      onChanged: deviceRepo.setDeviceOffline,
                    ),
                    _StatusSwitch(
                      label: 'Red celular offline',
                      value: status?.modem?.registered == false,
                      onChanged: deviceRepo.setCellularOffline,
                    ),
                    _StatusSwitch(
                      label: 'GNSS offline',
                      value: status?.gnss?.fix == false,
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
                      value: status?.adxl375?.ok == false,
                      onChanged: deviceRepo.setAdxl375Offline,
                    ),
                    _StatusSwitch(
                      label: 'LSM6DS3 offline',
                      value: status?.lsm6ds3?.ok == false,
                      onChanged: deviceRepo.setLsm6ds3Offline,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Disparar choque / vuelco (por severidad)',
                  children: [
                    _ActionButton(label: 'Choque leve', onPressed: () => eventRepo.triggerCrash(severity: AccidentSeverity.leve)),
                    _ActionButton(label: 'Choque moderado', onPressed: () => eventRepo.triggerCrash(severity: AccidentSeverity.moderado)),
                    _ActionButton(label: 'Choque grave', onPressed: () => eventRepo.triggerCrash(severity: AccidentSeverity.grave)),
                    _ActionButton(label: 'Vuelco grave', onPressed: () => eventRepo.triggerRollover(severity: AccidentSeverity.grave)),
                    _ActionButton(
                      label: 'Choque grave DIFERIDO (queued)',
                      onPressed: () => eventRepo.triggerCrash(severity: AccidentSeverity.grave, queued: true),
                    ),
                    _ActionButton(label: 'SOS', onPressed: eventRepo.triggerSos),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Eventos técnicos',
                  children: [
                    _ActionButton(label: 'Prueba de sistema (test)', onPressed: () => eventRepo.triggerTechnical(AccidentEventType.test)),
                    _ActionButton(label: 'Pérdida de alimentación', onPressed: () => eventRepo.triggerTechnical(AccidentEventType.powerLoss)),
                    _ActionButton(label: 'Batería baja', onPressed: () => eventRepo.triggerTechnical(AccidentEventType.lowBattery)),
                    _ActionButton(label: 'Reinicio del equipo', onPressed: () => eventRepo.triggerTechnical(AccidentEventType.booted)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Evento crítico actual',
                  children: [
                    Text(
                      criticalEvent == null
                          ? 'No hay ningún evento forzando la pantalla crítica.'
                          : '${criticalEvent.type.name} • ${criticalEvent.severity.name} • seq ${criticalEvent.seq} • ${classify(criticalEvent).name}',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActionButton(
                      label: 'Cancelar (simula botón CANCELAR del equipo)',
                      onPressed: criticalEvent == null ? null : () => eventRepo.triggerCancel(criticalEvent.seq),
                    ),
                    _ActionButton(
                      label: 'Marcar como atendido ("Ya lo vi")',
                      onPressed: criticalEvent == null ? null : () => context.read<EventProvider>().acknowledge(criticalEvent.dedupKey),
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
                            '${event.type.name} • ${event.severity.name} • seq ${event.seq} • ${classify(event).name}${event.queued ? ' • DIFERIDO' : ''}',
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
