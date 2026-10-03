import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/accident_event.dart';
import '../models/alert_presentation.dart';
import '../repositories/event_repository.dart';

/// Reactive to the signed-in user and their currently resolved vehicle.
/// When vehicleId is available, the repository combines current vehicle
/// events with historical events that are still associated only by userId.
class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepository;
  StreamSubscription<List<AccidentEvent>>? _eventsSubscription;
  String? _userId;
  String? _vehicleId;
  int _contextVersion = 0;

  List<AccidentEvent> _events = const [];
  List<AccidentEvent> get events => _events;

  AccidentEvent? _criticalEvent;
  AccidentEvent? get criticalEvent => _criticalEvent;

  Object? _error;
  Object? get error => _error;

  EventProvider(this._eventRepository);

  void setContext({required String? userId, String? vehicleId}) {
    if (_userId == userId && _vehicleId == vehicleId) return;
    final userChanged = _userId != userId;
    _userId = userId;
    _vehicleId = vehicleId;
    final contextVersion = ++_contextVersion;
    _error = null;

    _eventsSubscription?.cancel();
    if (userChanged) {
      _events = const [];
      _criticalEvent = null;
    }

    if (userId == null) {
      _events = const [];
      _criticalEvent = null;
      notifyListeners();
      return;
    }

    _eventsSubscription = _eventRepository
        .watchEvents(userId, vehicleId: vehicleId)
        .listen(
          (events) {
            if (contextVersion != _contextVersion) return;
            _events = events;
            _criticalEvent = _findCriticalEvent(events);
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (contextVersion != _contextVersion) return;
            _error = error;
            notifyListeners();
          },
        );
    notifyListeners();
  }

  AccidentEvent? _findCriticalEvent(List<AccidentEvent> events) {
    for (final event in events.reversed) {
      if (shouldForceCriticalScreen(event)) return event;
    }
    return null;
  }

  /// Capture the session user before starting the personal write.
  /// The event stream, not an optimistic local mutation, updates the UI.
  Future<void> acknowledge(String dedupKey) async {
    final userId = _userId;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('An authenticated user is required');
    }
    final contextVersion = _contextVersion;
    try {
      await _eventRepository.acknowledge(dedupKey, userId: userId);
    } catch (error) {
      if (contextVersion == _contextVersion) {
        _error = error;
        notifyListeners();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _contextVersion++;
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
