import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../models/accident_event.dart';
import '../../models/alert_presentation.dart';
import '../../models/user_incident_state.dart';
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
  final DatabaseReference _userIncidentStateRef;
  // The minimal per-user rules have been validated and deployed.
  final bool readUserIncidentState;

  FirebaseEventRepository({
    FirebaseDatabase? database,
    this.readUserIncidentState = true,
  }) : _eventsRef = (database ?? FirebaseDatabase.instance).ref('events'),
       _userIncidentStateRef = (database ?? FirebaseDatabase.instance).ref(
         'userIncidentState',
       );

  @override
  Stream<List<AccidentEvent>> watchEvents(String userId, {String? vehicleId}) {
    final userEvents = _watchRawEvents('userId', userId);
    final events = vehicleId == null
        ? userEvents.map(_parseAndSortEvents)
        : combineEventStreams(
            userEvents,
            _watchRawEvents('vehicleId', vehicleId),
          );
    if (!readUserIncidentState) return events;
    final states = _userIncidentStateRef.child(userId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <String, dynamic>{};
      if (value is! Map) {
        throw const FormatException('Invalid user incident state');
      }
      return Map<String, dynamic>.from(value);
    });
    return combineUserIncidentState(events, states, userId);
  }

  /// Read-only projection. An explicit personal false overrides legacy true.
  @visibleForTesting
  static Stream<List<AccidentEvent>> combineUserIncidentState(
    Stream<List<AccidentEvent>> events,
    Stream<Map<String, dynamic>> states,
    String userId,
  ) {
    late StreamController<List<AccidentEvent>> controller;
    StreamSubscription<List<AccidentEvent>>? eventSubscription;
    StreamSubscription<Map<String, dynamic>>? stateSubscription;
    List<AccidentEvent>? latestEvents;
    Map<String, dynamic>? latestStates;
    var completed = 0;

    void emit() {
      if (latestEvents == null || latestStates == null) return;
      controller.add(
        latestEvents!.map((event) {
          return applyUserIncidentState(
            event,
            userId,
            latestStates![event.dedupKey],
          );
        }).toList(),
      );
    }

    void done() {
      if (++completed == 2) controller.close();
    }

    controller = StreamController<List<AccidentEvent>>(
      onListen: () {
        eventSubscription = events.listen(
          (value) {
            latestEvents = value;
            emit();
          },
          onError: controller.addError,
          onDone: done,
        );
        stateSubscription = states.listen(
          (value) {
            latestStates = value;
            emit();
          },
          onError: controller.addError,
          onDone: done,
        );
      },
      onPause: () {
        eventSubscription?.pause();
        stateSubscription?.pause();
      },
      onResume: () {
        eventSubscription?.resume();
        stateSubscription?.resume();
      },
      onCancel: () async {
        await eventSubscription?.cancel();
        await stateSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<AccidentEvent?> watchCriticalEvent(
    String userId, {
    String? vehicleId,
  }) {
    return watchEvents(userId, vehicleId: vehicleId).map((events) {
      for (final event in events.reversed) {
        if (shouldForceCriticalScreen(event)) return event;
      }
      return null;
    });
  }

  @override
  Future<void> acknowledge(String dedupKey, {required String userId}) async {
    if (userId.trim().isEmpty) {
      throw StateError('An authenticated user is required');
    }
    await _userIncidentStateRef.child(userId).child(dedupKey).update({
      'acknowledged': true,
    });
  }

  Stream<Map<String, Map<String, dynamic>>> _watchRawEvents(
    String child,
    String value,
  ) {
    return _eventsRef.orderByChild(child).equalTo(value).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <String, Map<String, dynamic>>{};
      }

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
      );
    });
  }

  @visibleForTesting
  static Stream<List<AccidentEvent>> combineEventStreams(
    Stream<Map<String, Map<String, dynamic>>> userEvents,
    Stream<Map<String, Map<String, dynamic>>> vehicleEvents,
  ) {
    late StreamController<List<AccidentEvent>> controller;
    StreamSubscription<Map<String, Map<String, dynamic>>>? userSubscription;
    StreamSubscription<Map<String, Map<String, dynamic>>>? vehicleSubscription;
    var latestUserEvents = <String, Map<String, dynamic>>{};
    var latestVehicleEvents = <String, Map<String, dynamic>>{};

    void emitMergedEvents() {
      final merged = _mergeRawEvents(latestUserEvents, latestVehicleEvents);
      controller.add(_parseAndSortEvents(merged));
    }

    controller = StreamController<List<AccidentEvent>>(
      onListen: () {
        userSubscription = userEvents.listen((events) {
          latestUserEvents = events;
          emitMergedEvents();
        }, onError: controller.addError);
        vehicleSubscription = vehicleEvents.listen((events) {
          latestVehicleEvents = events;
          emitMergedEvents();
        }, onError: controller.addError);
      },
      onPause: () {
        userSubscription?.pause();
        vehicleSubscription?.pause();
      },
      onResume: () {
        userSubscription?.resume();
        vehicleSubscription?.resume();
      },
      onCancel: () async {
        await userSubscription?.cancel();
        await vehicleSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  static Map<String, Map<String, dynamic>> _mergeRawEvents(
    Map<String, Map<String, dynamic>> userEvents,
    Map<String, Map<String, dynamic>> vehicleEvents,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    void mergeSource(Map<String, Map<String, dynamic>> source) {
      for (final entry in source.entries) {
        final current = merged[entry.key];
        if (current == null) {
          merged[entry.key] = Map<String, dynamic>.from(entry.value);
          continue;
        }

        final combined = Map<String, dynamic>.from(current);
        for (final field in entry.value.entries) {
          if (field.value != null || !combined.containsKey(field.key)) {
            combined[field.key] = field.value;
          }
        }

        if (current['cancelledBySeq'] != null &&
            entry.value['cancelledBySeq'] == null) {
          combined['cancelledBySeq'] = current['cancelledBySeq'];
        }
        if (current['cancelledAt'] != null &&
            entry.value['cancelledAt'] == null) {
          combined['cancelledAt'] = current['cancelledAt'];
        }
        if (current['acknowledged'] == true ||
            entry.value['acknowledged'] == true) {
          combined['acknowledged'] = true;
        }

        merged[entry.key] = combined;
      }
    }

    mergeSource(userEvents);
    mergeSource(vehicleEvents);
    return merged;
  }

  static List<AccidentEvent> _parseAndSortEvents(
    Map<String, Map<String, dynamic>> raw,
  ) {
    if (raw.isEmpty) return const [];

    final events = raw.entries
        .map((entry) => AccidentEvent.fromJson(entry.key, entry.value))
        .toList();
    events.sort(
      (a, b) => (a.ts ?? a.receivedAt).compareTo(b.ts ?? b.receivedAt),
    );
    return events;
  }
}
