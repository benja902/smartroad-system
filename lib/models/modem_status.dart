/// Cellular modem status (docs/device_contract.md, `status.modem`).
/// `tech`/`operator` are free text from the modem, not a closed enum —
/// the device can report values this app has never seen before.
class ModemStatus {
  final bool registered;
  final String? tech;
  final String? operatorName;
  final int? rssiDbm;

  const ModemStatus({
    required this.registered,
    this.tech,
    this.operatorName,
    this.rssiDbm,
  });

  factory ModemStatus.fromJson(Map<String, dynamic> json) {
    return ModemStatus(
      registered: json['registered'] as bool? ?? false,
      tech: json['tech'] as String?,
      operatorName: json['operator'] as String?,
      rssiDbm: (json['rssi_dbm'] as num?)?.toInt(),
    );
  }
}

/// Signal-quality label derived purely for UI, per the thresholds the
/// manual gives as a rule of thumb (section 7.4): better than -85 dBm is
/// good, worse than -105 dBm is marginal. Never stored.
String signalQualityLabel(int? rssiDbm) {
  if (rssiDbm == null) return 'Desconocida';
  if (rssiDbm >= -85) return 'Buena';
  if (rssiDbm <= -105) return 'Marginal';
  return 'Regular';
}
