import 'dart:async';

import '../../models/accident_event.dart';
import '../../models/accident_event_type.dart';
import '../../models/accident_severity.dart';
import '../../models/alert_presentation.dart';
import '../../models/detection_data.dart';
import '../../models/user_incident_state.dart';
import '../event_repository.dart';
import 'mock_data_seed.dart';

/// Mock EventRepository. Also exposes dev-simulator-only trigger methods
/// (triggerCrash, triggerRollover, triggerSos, triggerCancel,
/// triggerTechnical) that live on this concrete class, not on the
/// EventRepository interface — the /dev panel casts to this type
/// explicitly, and these mirror the real firmware taxonomy instead of an
/// invented one.
class MockEventRepository implements EventRepository {
  final Map<String, AccidentEvent> _events = {};
  final Map<String, Map<String, bool>> _userIncidentState = {};
  final bool readUserIncidentState;

  MockEventRepository({this.readUserIncidentState = false});

  /// DEV fixture only; does not change the acknowledge production contract.
  void seedUserIncidentState(
    String userId,
    String eventKey, {
    required bool acknowledged,
  }) {
    (_userIncidentState[userId] ??= {})[eventKey] = acknowledged;
    _emit();
  }

  int _nextSeq = 1;

  final _eventsController = StreamController<List<AccidentEvent>>.broadcast();

  @override
  Stream<List<AccidentEvent>> watchEvents(
    String userId, {
    String? vehicleId,
  }) async* {
    yield _eventsFor(userId, vehicleId);
    yield* _eventsController.stream.map((_) => _eventsFor(userId, vehicleId));
  }

  @override
  Stream<AccidentEvent?> watchCriticalEvent(
    String userId, {
    String? vehicleId,
  }) async* {
    await for (final events in watchEvents(userId, vehicleId: vehicleId)) {
      yield _criticalEventFrom(events);
    }
  }

  List<AccidentEvent> get _sortedEvents {
    final list = _events.values.toList()
      ..sort((a, b) => (a.ts ?? a.receivedAt).compareTo(b.ts ?? b.receivedAt));
    return List.unmodifiable(list);
  }

  List<AccidentEvent> _eventsFor(String userId, String? vehicleId) {
    final events = vehicleId == null
        ? _sortedEvents
        : _sortedEvents
              .where(
                (event) =>
                    event.userId == userId || event.vehicleId == vehicleId,
              )
              .toList(growable: false);
    if (!readUserIncidentState) return List.unmodifiable(events);
    return List.unmodifiable(
      events.map((event) {
        final personal = _userIncidentState[userId]?[event.dedupKey];
        return applyUserIncidentState(
          event,
          userId,
          personal == null ? null : {'acknowledged': personal},
        );
      }),
    );
  }

  AccidentEvent? _criticalEventFrom(List<AccidentEvent> events) {
    for (final event in events.reversed) {
      if (shouldForceCriticalScreen(event)) return event;
    }
    return null;
  }

  AccidentEvent _triggerAccident({
    required AccidentEventType type,
    required AccidentSeverity severity,
    bool queued = false,
    String? vehicleId,
  }) {
    final seq = _nextSeq++;
    final now = DateTime.now();
    final occurredAt = queued ? now.subtract(const Duration(hours: 2)) : now;
    final event = AccidentEvent(
      deviceId: MockDataSeed.deviceId,
      type: type,
      seq: seq,
      ts: occurredAt,
      timeSrc: 'gnss',
      uptimeS: 48213,
      vehicleLabel: 'Camioneta 04',
      severity: severity,
      detection: type == AccidentEventType.sos
          ? null
          : DetectionData(
              peakG: severity == AccidentSeverity.grave
                  ? 42.0
                  : severity == AccidentSeverity.moderado
                  ? 30.0
                  : 18.0,
              deltaVKmh: severity == AccidentSeverity.grave ? 24.0 : 12.0,
              durationMs: 62,
              axisPeak: 'y',
              rollover: type == AccidentEventType.rollover,
            ),
      position: MockDataSeed.initialPosition,
      queued: queued,
      receivedAt: now,
      userId: MockDataSeed.userId,
      vehicleId: vehicleId,
    );
    _events[event.dedupKey] = event;
    _emit();
    return event;
  }

  AccidentEvent triggerCrash({
    AccidentSeverity severity = AccidentSeverity.grave,
    bool queued = false,
    String? vehicleId,
  }) {
    return _triggerAccident(
      type: AccidentEventType.crash,
      severity: severity,
      queued: queued,
      vehicleId: vehicleId,
    );
  }

  AccidentEvent triggerRollover({
    AccidentSeverity severity = AccidentSeverity.grave,
    bool queued = false,
    String? vehicleId,
  }) {
    return _triggerAccident(
      type: AccidentEventType.rollover,
      severity: severity,
      queued: queued,
      vehicleId: vehicleId,
    );
  }

  AccidentEvent triggerSos({bool queued = false, String? vehicleId}) {
    return _triggerAccident(
      type: AccidentEventType.sos,
      severity: AccidentSeverity.none,
      queued: queued,
      vehicleId: vehicleId,
    );
  }

  /// Simulates the physical CANCELAR button: publishes a `cancel` event
  /// (its own seq) referencing [cancelsSeq], and projects
  /// cancelledBySeq/cancelledAt onto the original — mirroring what the
  /// real bridge does with a merge write.
  void triggerCancel(int cancelsSeq) {
    final originalKey = '${MockDataSeed.deviceId}_$cancelsSeq';
    final original = _events[originalKey];

    final cancelSeq = _nextSeq++;
    final now = DateTime.now();
    _events['${MockDataSeed.deviceId}_$cancelSeq'] = AccidentEvent(
      deviceId: MockDataSeed.deviceId,
      type: AccidentEventType.cancel,
      seq: cancelSeq,
      ts: now,
      cancelsSeq: cancelsSeq,
      reason: 'button',
      elapsedS: original == null
          ? null
          : now.difference(original.ts ?? now).inSeconds,
      receivedAt: now,
      userId: MockDataSeed.userId,
    );

    if (original != null) {
      _events[originalKey] = original.copyWith(
        cancelledBySeq: cancelSeq,
        cancelledAt: now,
      );
    }
    _emit();
  }

  AccidentEvent triggerTechnical(AccidentEventType type) {
    assert(
      type == AccidentEventType.test ||
          type == AccidentEventType.powerLoss ||
          type == AccidentEventType.lowBattery ||
          type == AccidentEventType.booted,
    );
    final seq = _nextSeq++;
    final now = DateTime.now();
    final event = AccidentEvent(
      deviceId: MockDataSeed.deviceId,
      type: type,
      seq: seq,
      ts: now,
      severity: AccidentSeverity.none,
      receivedAt: now,
      userId: MockDataSeed.userId,
    );
    _events[event.dedupKey] = event;
    _emit();
    return event;
  }

  @override
  Future<void> acknowledge(String dedupKey) async {
    final event = _events[dedupKey];
    if (event == null) return;
    _events[dedupKey] = event.copyWith(acknowledged: true);
    _emit();
  }

  void _emit() {
    _eventsController.add(_sortedEvents);
  }
}
