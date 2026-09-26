// Low-priority diagnostic blocks from status.inputs/outputs/system
// (docs/device_contract.md). Not surfaced in the MVP UI yet — kept for
// model fidelity and future diagnostic screens.

class ButtonInputs {
  final bool sos;
  final bool cancel;

  const ButtonInputs({this.sos = false, this.cancel = false});

  factory ButtonInputs.fromJson(Map<String, dynamic> json) {
    return ButtonInputs(
      sos: json['sos'] as bool? ?? false,
      cancel: json['cancel'] as bool? ?? false,
    );
  }
}

class OutputSignals {
  final bool ledRed;
  final bool ledGreen;
  final bool buzzer;

  const OutputSignals({this.ledRed = false, this.ledGreen = false, this.buzzer = false});

  factory OutputSignals.fromJson(Map<String, dynamic> json) {
    return OutputSignals(
      ledRed: json['led_red'] as bool? ?? false,
      ledGreen: json['led_green'] as bool? ?? false,
      buzzer: json['buzzer'] as bool? ?? false,
    );
  }
}

class SystemDiagnostics {
  final int? uptimeS;
  final int? heapFree;
  final String? resetReason;

  const SystemDiagnostics({this.uptimeS, this.heapFree, this.resetReason});

  factory SystemDiagnostics.fromJson(Map<String, dynamic> json) {
    return SystemDiagnostics(
      uptimeS: (json['uptime_s'] as num?)?.toInt(),
      heapFree: (json['heap_free'] as num?)?.toInt(),
      resetReason: json['reset_reason'] as String?,
    );
  }
}
