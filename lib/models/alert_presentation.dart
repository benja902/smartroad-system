import 'accident_event.dart';
import 'accident_event_type.dart';
import 'accident_severity.dart';

/// How an event should be presented, derived purely from its fields —
/// never stored. See the plan's classification table
/// (docs de fase de alineación con el firmware) for the full rationale.
enum AlertPresentation {
  /// test/power_loss/low_battery/booted — never mixed with the accident
  /// feed, never affects the critical event.
  technical,

  /// A `cancel` event itself — not shown as its own row; its only effect
  /// is projecting cancelledBySeq/cancelledAt onto the event it references.
  cancellation,

  /// crash/rollover/sos that a `cancel` event referenced.
  cancelled,

  /// crash/rollover/sos the app user marked as seen (`acknowledged`).
  attended,

  /// Already happened (possibly hours ago) — arrived late from the
  /// device's offline queue. Never presented as "just happened".
  deferred,

  /// Forces the full-screen critical flow: sos, or crash/rollover with
  /// severity grave — live, not queued, not cancelled, not acknowledged.
  activeEmergency,

  /// crash/rollover with severity moderado — prominent but non-blocking.
  attention,

  /// crash/rollover with severity leve/none/unknown.
  informative,
}

AlertPresentation classify(AccidentEvent event) {
  if (event.type == AccidentEventType.test ||
      event.type == AccidentEventType.powerLoss ||
      event.type == AccidentEventType.lowBattery ||
      event.type == AccidentEventType.booted) {
    return AlertPresentation.technical;
  }
  if (event.type == AccidentEventType.cancel) {
    return AlertPresentation.cancellation;
  }

  // type ∈ {crash, rollover, sos, unknown} from here.
  if (event.cancelledBySeq != null) return AlertPresentation.cancelled;
  if (event.acknowledged) return AlertPresentation.attended;
  if (event.queued) return AlertPresentation.deferred;

  if (event.type == AccidentEventType.sos || event.severity == AccidentSeverity.grave) {
    return AlertPresentation.activeEmergency;
  }
  if (event.severity == AccidentSeverity.moderado) {
    return AlertPresentation.attention;
  }
  // leve, none, unknown, or an unrecognized event type.
  return AlertPresentation.informative;
}

/// Whether an event should force navigation to the full-screen critical
/// flow. Deliberately a separate function from [classify] — never inline
/// `classify(event) == AlertPresentation.activeEmergency` at call sites —
/// so a future presentation category can't accidentally change
/// interruption behavior.
bool shouldForceCriticalScreen(AccidentEvent event) {
  return classify(event) == AlertPresentation.activeEmergency;
}
