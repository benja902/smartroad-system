import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../models/accident_event.dart';
import '../../models/alert_presentation.dart';
import '../../models/user_incident_state.dart';
import '../event_repository.dart';

/// Firebase-backed EventRepository. events/{deviceId_seq} is a flat
/// collection written by the backend bridge (see docs/device_contract.md);
/// `userId` is denormalized for authorized owner queries.
///
/// Each feed query is bounded. Separate critical indexes keep older active
/// emergencies visible when they fall outside the recent event window.
class FirebaseEventRepository implements EventRepository {
  static const int eventQueryLimit = 100;
  final DatabaseReference _eventsRef;
  final DatabaseReference _readIndexRef;
  final DatabaseReference _userIncidentStateRef;
  // The minimal per-user rules have been validated and deployed.
  final bool readUserIncidentState;

  FirebaseEventRepository({
    FirebaseDatabase? database,
    this.readUserIncidentState = true,
  }) : _eventsRef = (database ?? FirebaseDatabase.instance).ref('events'),
       _readIndexRef = (database ?? FirebaseDatabase.instance).ref('eventReadIndex'),
       _userIncidentStateRef = (database ?? FirebaseDatabase.instance).ref(
         'userIncidentState',
       );

  @override
  Stream<List<AccidentEvent>> watchEvents(String userId, {String? vehicleId}) {
    final userEvents = _watchRecentEvents('users', userId);
    final legacyCritical = _watchRawEvents('criticalLegacyUserId', userId);
    final events = vehicleId == null
        ? combineEventStreams(userEvents, legacyCritical)
        : combineEventStreams(
            userEvents,
            _watchRecentEvents('vehicles', vehicleId),
            additionalEvents: [
              legacyCritical,
              _watchRawEvents('criticalVehicleId', vehicleId),
            ],
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
    return _eventsRef
        .orderByChild(child)
        .equalTo(value)
        .limitToLast(eventQueryLimit)
        .onValue
        .map((event) {
          final snapshot = event.snapshot;
          if (!snapshot.exists || snapshot.value == null) {
            return <String, Map<String, dynamic>>{};
          }

          final raw = Map<String, dynamic>.from(snapshot.value as Map);
          return raw.map(
            (key, value) =>
                MapEntry(key, Map<String, dynamic>.from(value as Map)),
          );
        });
  }

  Stream<Map<String, Map<String, dynamic>>> _watchRecentEvents(
    String scope,
    String id,
  ) {
    return _readIndexRef
        .child(scope)
        .child(id)
        .orderByKey()
        .limitToLast(eventQueryLimit)
        .onValue
        .asyncMap((event) async {
          final value = event.snapshot.value;
          if (value == null) return <String, Map<String, dynamic>>{};
          if (value is! Map) {
            throw const FormatException('Invalid event read index');
          }
          final pointers = Map<String, dynamic>.from(value);
          final keys = <String>[];
          for (final pointer in pointers.values) {
            if (pointer is! Map || pointer['eventKey'] is! String) {
              throw const FormatException('Invalid event read pointer');
            }
            keys.add(pointer['eventKey'] as String);
          }
          final snapshots = await Future.wait(
            keys.map((key) => _eventsRef.child(key).get()),
          );
          final rows = <String, Map<String, dynamic>>{};
          for (var i = 0; i < keys.length; i++) {
            if (snapshots[i].value case final Map raw) {
              rows[keys[i]] = Map<String, dynamic>.from(raw);
            }
          }
          return rows;
        });
  }

  @visibleForTesting
  static Stream<List<AccidentEvent>> combineEventStreams(
    Stream<Map<String, Map<String, dynamic>>> userEvents,
    Stream<Map<String, Map<String, dynamic>>> vehicleEvents, {
    List<Stream<Map<String, Map<String, dynamic>>>> additionalEvents = const [],
  }) {
    late StreamController<List<AccidentEvent>> controller;
    final sources = [userEvents, vehicleEvents, ...additionalEvents];
    final latest = List.generate(
      sources.length,
      (_) => <String, Map<String, dynamic>>{},
    );
    final subscriptions =
        <StreamSubscription<Map<String, Map<String, dynamic>>>>[];

    void emitMergedEvents() {
      var merged = <String, Map<String, dynamic>>{};
      for (final source in latest) {
        merged = _mergeRawEvents(merged, source);
      }
      controller.add(_parseAndSortEvents(merged));
    }

    controller = StreamController<List<AccidentEvent>>(
      onListen: () {
        for (var i = 0; i < sources.length; i++) {
          final index = i;
          subscriptions.add(
            sources[i].listen((events) {
              latest[index] = events;
              emitMergedEvents();
            }, onError: controller.addError),
          );
        }
      },
      onPause: () {
        for (final subscription in subscriptions) {
          subscription.pause();
        }
      },
      onResume: () {
        for (final subscription in subscriptions) {
          subscription.resume();
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
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
        if (current['queued'] == true || entry.value['queued'] == true) {
          combined['queued'] = true;
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
      (a, b) {
        final aTime = a.ts ?? a.receivedAt;
        final bTime = b.ts ?? b.receivedAt;
        if (aTime == null || bTime == null) {
          if (aTime == null && bTime == null) return a.dedupKey.compareTo(b.dedupKey);
          return aTime == null ? -1 : 1;
        }
        return aTime.compareTo(bTime);
      },
    );
    return events;
  }
}
