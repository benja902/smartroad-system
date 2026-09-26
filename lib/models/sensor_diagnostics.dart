// Per-sensor diagnostics on the I2C bus (docs/device_contract.md,
// `status.sensors`). Three physical devices share the bus: ADXL375
// (impact), LSM6DS3TR-C (orientation/gyro), and PCF8574 (button/LED/
// buzzer expander — a missing PCF8574 means no buttons, LEDs, or buzzer).

class AdxlSensorStatus {
  final bool ok;
  final String? address;
  final double? peakG60s;

  const AdxlSensorStatus({required this.ok, this.address, this.peakG60s});

  factory AdxlSensorStatus.fromJson(Map<String, dynamic> json) {
    return AdxlSensorStatus(
      ok: json['ok'] as bool? ?? false,
      address: json['addr'] as String?,
      peakG60s: (json['peak_g_60s'] as num?)?.toDouble(),
    );
  }
}

class ImuSensorStatus {
  final bool ok;
  final String? address;
  final double? tiltDeg;
  final double? gyroMaxDps;

  const ImuSensorStatus({required this.ok, this.address, this.tiltDeg, this.gyroMaxDps});

  factory ImuSensorStatus.fromJson(Map<String, dynamic> json) {
    return ImuSensorStatus(
      ok: json['ok'] as bool? ?? false,
      address: json['addr'] as String?,
      tiltDeg: (json['tilt_deg'] as num?)?.toDouble(),
      gyroMaxDps: (json['gyro_max_dps'] as num?)?.toDouble(),
    );
  }
}

class ExpanderStatus {
  final bool ok;
  final String? address;

  const ExpanderStatus({required this.ok, this.address});

  factory ExpanderStatus.fromJson(Map<String, dynamic> json) {
    return ExpanderStatus(
      ok: json['ok'] as bool? ?? false,
      address: json['addr'] as String?,
    );
  }
}
