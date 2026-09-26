import 'accident_event_type.dart';
import 'accident_severity.dart';

/// Display-only severity label for crash/rollover events, derived purely
/// from `severity` — never persisted, never used to decide whether to
/// force the critical screen (see AlertPresentation.shouldForceCriticalScreen
/// for that). Kept only because the Stitch-designed Alertas UI already
/// shows a "Nivel X" pill; SOS, cancellations, and technical events don't
/// map onto this scale and must not be forced into it.
enum AccidentLevel { level1, level2, level3 }

/// Returns null for event types this scale doesn't apply to (sos, cancel,
/// technical events) — callers must handle that case explicitly rather
/// than guessing a level.
AccidentLevel? deriveAccidentLevel(AccidentEventType type, AccidentSeverity severity) {
  if (type != AccidentEventType.crash && type != AccidentEventType.rollover) return null;
  switch (severity) {
    case AccidentSeverity.leve:
      return AccidentLevel.level1;
    case AccidentSeverity.moderado:
      return AccidentLevel.level2;
    case AccidentSeverity.grave:
      return AccidentLevel.level3;
    case AccidentSeverity.none:
    case AccidentSeverity.unknown:
      return null;
  }
}
