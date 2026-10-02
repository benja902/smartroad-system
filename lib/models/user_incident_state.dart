import 'accident_event.dart';

/// Projects personal read state without modifying the canonical incident.
AccidentEvent applyUserIncidentState(
  AccidentEvent event,
  String userId,
  Object? state,
) {
  final personal = state is Map ? state['acknowledged'] : null;
  final legacy = event.vehicleId == null && event.userId == userId;
  return event.copyWith(
    acknowledged: personal is bool ? personal : legacy && event.acknowledged,
  );
}
