/// GNSS fix, shared shape between the `status.gnss` block and an event's
/// embedded `position` block (docs/device_contract.md). All fields come
/// from the firmware — there's no human-readable place name, since the
/// device never resolves one; a `displayName` would have to be derived by
/// Flutter (e.g. reverse geocoding), not part of this model yet.
class GnssPosition {
  final bool fix;
  final double latitude;
  final double longitude;
  final double? altitudeM;
  final double? speedKmh;
  final double? heading;
  final double? hdop;
  final int? satellites;

  /// Age of this fix in seconds. Large values mean the shown coordinates
  /// are stale — always prefer honesty over a confident-looking pin.
  final int? fixAgeS;

  const GnssPosition({
    required this.fix,
    required this.latitude,
    required this.longitude,
    this.altitudeM,
    this.speedKmh,
    this.heading,
    this.hdop,
    this.satellites,
    this.fixAgeS,
  });

  factory GnssPosition.fromJson(Map<String, dynamic> json) {
    return GnssPosition(
      fix: json['fix'] as bool? ?? false,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      altitudeM: (json['alt_m'] as num?)?.toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      hdop: (json['hdop'] as num?)?.toDouble(),
      satellites: (json['sats'] as num?)?.toInt(),
      fixAgeS: (json['fix_age_s'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fix': fix,
      'lat': latitude,
      'lon': longitude,
      'alt_m': altitudeM,
      'speed_kmh': speedKmh,
      'heading': heading,
      'hdop': hdop,
      'sats': satellites,
      'fix_age_s': fixAgeS,
    };
  }
}
