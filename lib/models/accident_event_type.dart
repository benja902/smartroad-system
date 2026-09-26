/// Mirrors the firmware's `type` field exactly (docs/device_contract.md).
/// `unknown` is a defensive fallback for a value the app doesn't recognize
/// yet — never thrown away, never silently mapped to something else.
enum AccidentEventType {
  crash,
  rollover,
  sos,
  cancel,
  test,
  powerLoss,
  lowBattery,
  booted,
  unknown;

  static AccidentEventType parse(String? value) {
    switch (value) {
      case 'crash':
        return AccidentEventType.crash;
      case 'rollover':
        return AccidentEventType.rollover;
      case 'sos':
        return AccidentEventType.sos;
      case 'cancel':
        return AccidentEventType.cancel;
      case 'test':
        return AccidentEventType.test;
      case 'power_loss':
        return AccidentEventType.powerLoss;
      case 'low_battery':
        return AccidentEventType.lowBattery;
      case 'booted':
        return AccidentEventType.booted;
      default:
        return AccidentEventType.unknown;
    }
  }
}
