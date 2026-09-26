import 'package:firebase_database/firebase_database.dart';

import '../../models/accident_event.dart';
import '../../models/alert_presentation.dart';
import '../event_repository.dart';

/// Firebase-backed EventRepository. events/{deviceId_seq} is a flat
/// collection written by the backend bridge (see docs/device_contract.md);
/// `userId` is denormalized and indexed so per-user queries stay cheap.
///
/// watchCriticalEvent derives the active critical event by filtering the
/// same per-user event stream client-side rather than reading a separate
/// RTDB node — a small bandwidth trade-off (downloading a user's event
/// history instead of a single pointer value) for not requiring the
/// bridge to also maintain a dedicated "critical pointer" node.
class FirebaseEventRepository implements EventRepository {
  final DatabaseReference _eventsRef;

  FirebaseEventRepository({FirebaseDatabase? database})
      : _eventsRef = (database ?? FirebaseDatabase.instance).ref('events');

  @override
  Stream<List<AccidentEvent>> watchEvents(String userId) {
    return _eventsRef.orderByChild('userId').equalTo(userId).onValue.map((event) {
      final events = _parseEvents(event.snapshot);
      events.sort((a, b) => (a.ts ?? a.receivedAt).compareTo(b.ts ?? b.receivedAt));
      return events;
    });
  }

  @override
  Stream<AccidentEvent?> watchCriticalEvent(String userId) {
    return watchEvents(userId).map((events) {
      for (final event in events.reversed) {
        if (shouldForceCriticalScreen(event)) return event;
      }
      return null;
    });
  }

  @override
  Future<void> acknowledge(String dedupKey) {
    return _eventsRef.child(dedupKey).update({'acknowledged': true});
  }

  List<AccidentEvent> _parseEvents(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) return const [];

    final raw = Map<String, dynamic>.from(snapshot.value as Map);
    return raw.entries
        .map((entry) => AccidentEvent.fromJson(entry.key, Map<String, dynamic>.from(entry.value as Map)))
        .toList();
  }
}
