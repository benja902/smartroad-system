import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/accident_event.dart';
import '../repositories/event_repository.dart';

/// Reactive to the signed-in user: call [setUserId] whenever
/// SessionProvider's user changes (see AppProviders) rather than passing a
/// fixed userId at construction, since the real user is only known after
/// Firebase Auth resolves.
class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepository;
  StreamSubscription<List<AccidentEvent>>? _eventsSubscription;
  StreamSubscription<AccidentEvent?>? _criticalSubscription;
  String? _userId;

  List<AccidentEvent> _events = const [];
  List<AccidentEvent> get events => _events;

  AccidentEvent? _criticalEvent;
  AccidentEvent? get criticalEvent => _criticalEvent;

  EventProvider(this._eventRepository);

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;

    _eventsSubscription?.cancel();
    _criticalSubscription?.cancel();
    _events = const [];
    _criticalEvent = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    _eventsSubscription = _eventRepository.watchEvents(userId).listen((events) {
      _events = events;
      notifyListeners();
    });
    _criticalSubscription = _eventRepository.watchCriticalEvent(userId).listen((event) {
      _criticalEvent = event;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> confirmEmergency(String eventId) => _eventRepository.confirmEmergency(eventId);

  Future<void> cancelAlert(String eventId) => _eventRepository.cancelAlert(eventId);

  Future<void> closeIncident(String eventId) => _eventRepository.closeIncident(eventId);

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _criticalSubscription?.cancel();
    super.dispose();
  }
}
