/// Power supply status (docs/device_contract.md, `status.power`).
class PowerStatus {
  final double? batteryV;
  final bool charging;

  /// false means the device is running on battery — external power (USB-C
  /// or solar) is not present.
  final bool vinOk;

  const PowerStatus({this.batteryV, this.charging = false, this.vinOk = true});

  factory PowerStatus.fromJson(Map<String, dynamic> json) {
    return PowerStatus(
      batteryV: (json['battery_v'] as num?)?.toDouble(),
      charging: json['charging'] as bool? ?? false,
      vinOk: json['vin_ok'] as bool? ?? true,
    );
  }
}
