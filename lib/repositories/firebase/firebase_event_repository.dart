import 'package:firebase_database/firebase_database.dart';

import '../../models/accident_event.dart';
import '../../models/accident_level.dart';
import '../../models/event_status.dart';
import '../../models/location_model.dart';
import '../event_repository.dart';

/// Firebase-backed EventRepository. events/{eventId} is a flat collection
/// (see docs/device_contract.md); `userId` is indexed (database.rules.json)
/// so per-user queries stay cheap.
///
/// watchCriticalEvent derives the active critical event by filtering the
/// same per-user event stream client-side rather than reading a separate
/// RTDB node. That trades a small amount of bandwidth (downloading a
/// user's event history instead of a single pointer value) for not
/// requiring a Cloud Function to maintain a dedicated "critical pointer"
/// node — acceptable for the event volumes expected at this stage; revisit
/// with a maintained pointer node if per-user event history grows large.
class FirebaseEventRepository implements EventRepository {
  final DatabaseReference _eventsRef;

  FirebaseEventRepository({FirebaseDatabase? database})
      : _eventsRef = (database ?? FirebaseDatabase.instance).ref('events');

  @override
  Stream<List<AccidentEvent>> watchEvents(String userId) {
    return _eventsRef.orderByChild('userId').equalTo(userId).onValue.map((event) {
      final events = _parseEvents(event.snapshot);
      events.sort((a, b) => a.detectedAt.compareTo(b.detectedAt));
      return events;
    });
  }

  @override
  Stream<AccidentEvent?> watchCriticalEvent(String userId) {
    return watchEvents(userId).map((events) {
      for (final event in events.reversed) {
        if (event.isActiveCritical) return event;
      }
      return null;
    });
  }

  @override
  Future<void> confirmEmergency(String eventId) {
    return _eventsRef.child(eventId).update({'status': EventStatus.emergencyActive.name});
  }

  @override
  Future<void> cancelAlert(String eventId) {
    return _eventsRef.child(eventId).update({'status': EventStatus.cancelled.name});
  }

  @override
  Future<void> closeIncident(String eventId) {
    return _eventsRef.child(eventId).update({'status': EventStatus.closed.name});
  }

  List<AccidentEvent> _parseEvents(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) return const [];

    final raw = Map<String, dynamic>.from(snapshot.value as Map);
    return raw.entries.map((entry) => _parseEvent(entry.key, entry.value)).toList();
  }

  AccidentEvent _parseEvent(String id, Object? value) {
    final data = Map<String, dynamic>.from(value as Map);
    final locationData = data['location'];

    return AccidentEvent(
      id: id,
      deviceId: data['deviceId'] as String,
      userId: data['userId'] as String,
      level: AccidentLevel.values.byName(data['level'] as String),
      status: EventStatus.values.byName(data['status'] as String),
      detectedAt: DateTime.fromMillisecondsSinceEpoch((data['detectedAt'] as num).toInt()),
      deadline: data['deadline'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((data['deadline'] as num).toInt()),
      peakG: (data['peakG'] as num?)?.toDouble(),
      location: locationData == null
          ? null
          : LocationModel(
              latitude: (locationData['latitude'] as num).toDouble(),
              longitude: (locationData['longitude'] as num).toDouble(),
              displayName: locationData['displayName'] as String?,
              updatedAt: DateTime.fromMillisecondsSinceEpoch((locationData['updatedAt'] as num).toInt()),
            ),
      contactsNotified: (data['contactsNotified'] as num?)?.toInt() ?? 0,
      rescueNotified: data['rescueNotified'] as bool? ?? false,
    );
  }
}
