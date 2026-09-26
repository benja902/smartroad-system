/// Impact/rollover measurement block, present only on `crash`/`rollover`
/// events (docs/device_contract.md, `detection`).
class DetectionData {
  final double? peakG;
  final double? deltaVKmh;
  final int? durationMs;
  final String? axisPeak;
  final bool rollover;
  final double? tiltDeg;
  final double? gyroMaxDps;

  const DetectionData({
    this.peakG,
    this.deltaVKmh,
    this.durationMs,
    this.axisPeak,
    this.rollover = false,
    this.tiltDeg,
    this.gyroMaxDps,
  });

  factory DetectionData.fromJson(Map<String, dynamic> json) {
    return DetectionData(
      peakG: (json['peak_g'] as num?)?.toDouble(),
      deltaVKmh: (json['delta_v_kmh'] as num?)?.toDouble(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      axisPeak: json['axis_peak'] as String?,
      rollover: json['rollover'] as bool? ?? false,
      tiltDeg: (json['tilt_deg'] as num?)?.toDouble(),
      gyroMaxDps: (json['gyro_max_dps'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peak_g': peakG,
      'delta_v_kmh': deltaVKmh,
      'duration_ms': durationMs,
      'axis_peak': axisPeak,
      'rollover': rollover,
      'tilt_deg': tiltDeg,
      'gyro_max_dps': gyroMaxDps,
    };
  }
}
