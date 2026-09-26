import '../models/accident_event.dart';

abstract class EventRepository {
  /// Full event log for a user — feeds Alertas and Home's recent-alerts list.
  Stream<List<AccidentEvent>> watchEvents(String userId);

  /// The single most recent event where shouldForceCriticalScreen() is
  /// true, or null. Kept as its own stream (not derived client-side from
  /// [watchEvents]) so the router's redirect has a cheap, single-purpose
  /// signal.
  Stream<AccidentEvent?> watchCriticalEvent(String userId);

  /// The only mutation the app is allowed to make on an event — marks it
  /// as seen by the user. This is what lets the critical screen stop
  /// forcing itself even if the physical CANCELAR button on the device
  /// was never pressed (e.g. a false alarm nobody cancels from the
  /// equipment).
  Future<void> acknowledge(String dedupKey);
}
