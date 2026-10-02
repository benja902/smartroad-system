import '../models/accident_event.dart';

abstract class EventRepository {
  /// Full event log for a user — feeds Alertas and Home's recent-alerts list.
  /// When [vehicleId] is available, implementations may combine current
  /// vehicle events with historical records associated only by [userId].
  Stream<List<AccidentEvent>> watchEvents(String userId, {String? vehicleId});

  /// The single most recent event where shouldForceCriticalScreen() is true,
  /// or null. Implementations derive it from the same merged event view so
  /// historical and vehicle-associated records follow identical semantics.
  Stream<AccidentEvent?> watchCriticalEvent(String userId, {String? vehicleId});

  /// The only mutation the app is allowed to make on an event — marks it
  /// as seen by the user. This is what lets the critical screen stop
  /// forcing itself even if the physical CANCELAR button on the device
  /// was never pressed (e.g. a false alarm nobody cancels from the
  /// equipment).
  Future<void> acknowledge(String dedupKey);
}
