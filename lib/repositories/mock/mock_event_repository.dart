import 'dart:async';

import '../../models/accident_event.dart';
import '../../models/accident_level.dart';
import '../../models/event_status.dart';
import '../event_repository.dart';
import 'mock_data_seed.dart';

/// Mock EventRepository. Also exposes dev-simulator-only trigger methods
/// (triggerLevel1/2/3) that live on this concrete class, not on the
/// EventRepository interface — the /dev panel casts to this type
/// explicitly, keeping the production-facing interface clean.
class MockEventRepository implements EventRepository {
  final List<AccidentEvent> _events = [];
  int _nextId = 1;

  final _eventsController = StreamController<List<AccidentEvent>>.broadcast();
  final _criticalController = StreamController<AccidentEvent?>.broadcast();

  @override
  Stream<List<AccidentEvent>> watchEvents(String userId) async* {
    yield List.unmodifiable(_events);
    yield* _eventsController.stream;
  }

  @override
  Stream<AccidentEvent?> watchCriticalEvent(String userId) async* {
    yield _criticalEvent;
    yield* _criticalController.stream;
  }

  AccidentEvent? get _criticalEvent {
    for (final event in _events.reversed) {
      if (event.isActiveCritical) return event;
    }
    return null;
  }

  /// Level1: registered directly as `detected`, never leaves that status
  /// except being superseded by a later event. Does not trigger navigation.
  AccidentEvent triggerLevel1() {
    final event = AccidentEvent(
      id: _generateId(),
      deviceId: MockDataSeed.deviceId,
      userId: MockDataSeed.userId,
      level: AccidentLevel.level1,
      status: EventStatus.detected,
      detectedAt: DateTime.now(),
      location: MockDataSeed.initialLocation,
      peakG: 2.1,
    );
    return _add(event);
  }

  /// Level2: starts in `pendingConfirmation` with a 15s wall-clock deadline
  /// so the countdown UI can derive remaining time from `deadline` instead
  /// of owning a local timer duration.
  AccidentEvent triggerLevel2() {
    final now = DateTime.now();
    final event = AccidentEvent(
      id: _generateId(),
      deviceId: MockDataSeed.deviceId,
      userId: MockDataSeed.userId,
      level: AccidentLevel.level2,
      status: EventStatus.pendingConfirmation,
      detectedAt: now,
      deadline: now.add(const Duration(seconds: 15)),
      location: MockDataSeed.initialLocation,
      peakG: 5.4,
      contactsNotified: 2,
    );
    return _add(event);
  }

  /// Level3: skips pendingConfirmation entirely, active immediately.
  AccidentEvent triggerLevel3() {
    final event = AccidentEvent(
      id: _generateId(),
      deviceId: MockDataSeed.deviceId,
      userId: MockDataSeed.userId,
      level: AccidentLevel.level3,
      status: EventStatus.emergencyActive,
      detectedAt: DateTime.now(),
      location: MockDataSeed.initialLocation,
      peakG: 9.8,
      contactsNotified: 3,
      rescueNotified: true,
    );
    return _add(event);
  }

  @override
  Future<void> confirmEmergency(String eventId) async {
    _update(eventId, (event) => event.copyWith(status: EventStatus.emergencyActive));
  }

  @override
  Future<void> cancelAlert(String eventId) async {
    _update(eventId, (event) => event.copyWith(status: EventStatus.cancelled));
  }

  @override
  Future<void> closeIncident(String eventId) async {
    _update(eventId, (event) => event.copyWith(status: EventStatus.closed));
  }

  String _generateId() => 'event-${_nextId++}';

  AccidentEvent _add(AccidentEvent event) {
    _events.add(event);
    _emit();
    return event;
  }

  void _update(String eventId, AccidentEvent Function(AccidentEvent) transform) {
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index == -1) return;
    _events[index] = transform(_events[index]);
    _emit();
  }

  void _emit() {
    _eventsController.add(List.unmodifiable(_events));
    _criticalController.add(_criticalEvent);
  }
}
