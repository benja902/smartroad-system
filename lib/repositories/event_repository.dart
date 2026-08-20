import '../models/accident_event.dart';

abstract class EventRepository {
  /// Full event log for a user — feeds Alertas and Home's recent-alerts list.
  Stream<List<AccidentEvent>> watchEvents(String userId);

  /// The single most recent non-resolved level2/level3 event, or null.
  /// Kept as its own stream (not derived client-side from [watchEvents])
  /// so the app router's redirect has a cheap, single-purpose signal, and
  /// so a future Firebase implementation can point this at a small
  /// dedicated RTDB node instead of downloading the full event history.
  Stream<AccidentEvent?> watchCriticalEvent(String userId);

  /// User pressed "Necesito ayuda ahora", or a level2 countdown expired.
  Future<void> confirmEmergency(String eventId);

  /// User pressed "Cancelar alerta" during a level2 pendingConfirmation.
  Future<void> cancelAlert(String eventId);

  Future<void> closeIncident(String eventId);
}
