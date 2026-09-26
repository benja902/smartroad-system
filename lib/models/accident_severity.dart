/// Mirrors the firmware's `severity` field. Only meaningful for
/// crash/rollover events — sos/test/power_loss/etc. should not depend on
/// severity for presentation. `unknown` is a defensive fallback for a
/// value the app doesn't recognize (e.g. a future firmware adding a new
/// one) — treated the same as `none` for presentation, never trusted to
/// force the critical screen.
enum AccidentSeverity {
  leve,
  moderado,
  grave,
  none,
  unknown;

  static AccidentSeverity parse(String? value) {
    switch (value) {
      case 'leve':
        return AccidentSeverity.leve;
      case 'moderado':
        return AccidentSeverity.moderado;
      case 'grave':
        return AccidentSeverity.grave;
      case 'none':
      case null:
        return AccidentSeverity.none;
      default:
        return AccidentSeverity.unknown;
    }
  }
}
