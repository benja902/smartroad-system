import 'device_diagnostics.dart';
import 'device_operational_state.dart';
import 'gnss_position.dart';
import 'modem_status.dart';
import 'power_status.dart';
import 'sensor_diagnostics.dart';
import 'storage_status.dart';

/// Mirrors the firmware's `status` message (docs/device_contract.md),
/// grouped by origin the same way the wire payload is. `online` is not
/// part of `status` — it comes from the separate `availability` channel
/// (LWT semantics: "the link dropped", not "stopped watching"), paired
/// with `lastSeen` so the UI can tell how fresh everything else is.
class DeviceStatus {
  final String deviceId;
  final DeviceOperationalState state;
  final String? firmwareVersion;

  final AdxlSensorStatus? adxl375;
  final ImuSensorStatus? lsm6ds3;
  final ExpanderStatus? pcf8574;

  final ButtonInputs? inputs;
  final OutputSignals? outputs;

  final StorageStatus? storage;
  final ModemStatus? modem;
  final GnssPosition? gnss;
  final PowerStatus? power;
  final SystemDiagnostics? system;

  /// From the `availability` MQTT topic (Last Will and Testament) via the
  /// bridge — not from `status.state`.
  final bool online;
  final DateTime lastSeen;

  const DeviceStatus({
    required this.deviceId,
    this.state = DeviceOperationalState.unknown,
    this.firmwareVersion,
    this.adxl375,
    this.lsm6ds3,
    this.pcf8574,
    this.inputs,
    this.outputs,
    this.storage,
    this.modem,
    this.gnss,
    this.power,
    this.system,
    this.online = false,
    required this.lastSeen,
  });

  /// Convenience for the mock repository (dev simulator toggles) and
  /// tests. The real Firebase repository never mutates a DeviceStatus —
  /// it only ever parses fresh ones from snapshots.
  DeviceStatus copyWith({
    DeviceOperationalState? state,
    AdxlSensorStatus? adxl375,
    ImuSensorStatus? lsm6ds3,
    ExpanderStatus? pcf8574,
    StorageStatus? storage,
    ModemStatus? modem,
    GnssPosition? gnss,
    PowerStatus? power,
    bool? online,
    DateTime? lastSeen,
  }) {
    return DeviceStatus(
      deviceId: deviceId,
      state: state ?? this.state,
      firmwareVersion: firmwareVersion,
      adxl375: adxl375 ?? this.adxl375,
      lsm6ds3: lsm6ds3 ?? this.lsm6ds3,
      pcf8574: pcf8574 ?? this.pcf8574,
      inputs: inputs,
      outputs: outputs,
      storage: storage ?? this.storage,
      modem: modem ?? this.modem,
      gnss: gnss ?? this.gnss,
      power: power ?? this.power,
      system: system,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  factory DeviceStatus.fromJson(String deviceId, Map<String, dynamic> json) {
    Map<String, dynamic>? section(String key) {
      final value = json[key];
      return value == null ? null : Map<String, dynamic>.from(value as Map);
    }

    final sensors = section('sensors');
    final availability = section('availability');

    return DeviceStatus(
      deviceId: deviceId,
      state: DeviceOperationalState.parse(json['state'] as String?),
      firmwareVersion: json['fw'] as String?,
      adxl375: sensors?['adxl375'] == null
          ? null
          : AdxlSensorStatus.fromJson(Map<String, dynamic>.from(sensors!['adxl375'] as Map)),
      lsm6ds3: sensors?['lsm6ds3tr'] == null
          ? null
          : ImuSensorStatus.fromJson(Map<String, dynamic>.from(sensors!['lsm6ds3tr'] as Map)),
      pcf8574: sensors?['pcf8574'] == null
          ? null
          : ExpanderStatus.fromJson(Map<String, dynamic>.from(sensors!['pcf8574'] as Map)),
      inputs: section('inputs') == null ? null : ButtonInputs.fromJson(section('inputs')!),
      outputs: section('outputs') == null ? null : OutputSignals.fromJson(section('outputs')!),
      storage: section('sd') == null ? null : StorageStatus.fromJson(section('sd')!),
      modem: section('modem') == null ? null : ModemStatus.fromJson(section('modem')!),
      gnss: section('gnss') == null ? null : GnssPosition.fromJson(section('gnss')!),
      power: section('power') == null ? null : PowerStatus.fromJson(section('power')!),
      system: section('system') == null ? null : SystemDiagnostics.fromJson(section('system')!),
      online: availability?['online'] as bool? ?? json['online'] as bool? ?? false,
      lastSeen: json['lastSeen'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch((json['lastSeen'] as num).toInt()),
    );
  }
}
