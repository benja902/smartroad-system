/// Device diagnostics snapshot embedded in every event
/// (docs/device_contract.md, `device`) — a picture of the equipment's
/// condition at the moment the event was generated, distinct from the
/// live DeviceStatus which reflects the current moment.
class EventDeviceSnapshot {
  final double? batteryV;
  final int? rssiDbm;
  final String? operatorName;
  final int? uptimeS;
  final bool sd;
  final bool degraded;

  const EventDeviceSnapshot({
    this.batteryV,
    this.rssiDbm,
    this.operatorName,
    this.uptimeS,
    this.sd = false,
    this.degraded = false,
  });

  factory EventDeviceSnapshot.fromJson(Map<String, dynamic> json) {
    return EventDeviceSnapshot(
      batteryV: (json['battery_v'] as num?)?.toDouble(),
      rssiDbm: (json['rssi_dbm'] as num?)?.toInt(),
      operatorName: json['operator'] as String?,
      uptimeS: (json['uptime_s'] as num?)?.toInt(),
      sd: json['sd'] as bool? ?? false,
      degraded: json['degraded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'battery_v': batteryV,
      'rssi_dbm': rssiDbm,
      'operator': operatorName,
      'uptime_s': uptimeS,
      'sd': sd,
      'degraded': degraded,
    };
  }
}
