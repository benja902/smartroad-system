import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_level.dart';
import 'package:smartroad/models/event_status.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';

void main() {
  group('MockEventRepository state machine', () {
    test('level1 stays in detected', () {
      final repo = MockEventRepository();
      final event = repo.triggerLevel1();

      expect(event.level, AccidentLevel.level1);
      expect(event.status, EventStatus.detected);
    });

    test('level2 starts pendingConfirmation with a future deadline', () {
      final repo = MockEventRepository();
      final event = repo.triggerLevel2();

      expect(event.level, AccidentLevel.level2);
      expect(event.status, EventStatus.pendingConfirmation);
      expect(event.deadline, isNotNull);
      expect(event.deadline!.isAfter(DateTime.now()), isTrue);
    });

    test('level2 confirmEmergency transitions to emergencyActive', () async {
      final repo = MockEventRepository();
      final event = repo.triggerLevel2();

      await repo.confirmEmergency(event.id);

      final critical = await repo.watchCriticalEvent('user-1').first;
      expect(critical!.status, EventStatus.emergencyActive);
    });

    test('level2 cancelAlert transitions to cancelled and clears critical event', () async {
      final repo = MockEventRepository();
      final event = repo.triggerLevel2();

      await repo.cancelAlert(event.id);

      final critical = await repo.watchCriticalEvent('user-1').first;
      expect(critical, isNull);
    });

    test('level3 goes straight to emergencyActive, no pendingConfirmation', () {
      final repo = MockEventRepository();
      final event = repo.triggerLevel3();

      expect(event.level, AccidentLevel.level3);
      expect(event.status, EventStatus.emergencyActive);
      expect(event.deadline, isNull);
    });

    test('closeIncident clears the critical event', () async {
      final repo = MockEventRepository();
      final event = repo.triggerLevel3();

      await repo.closeIncident(event.id);

      final critical = await repo.watchCriticalEvent('user-1').first;
      expect(critical, isNull);
    });

    test('watchEvents replays current state to new subscribers', () async {
      final repo = MockEventRepository();
      repo.triggerLevel1();
      repo.triggerLevel2();

      final events = await repo.watchEvents('user-1').first;
      expect(events, hasLength(2));
    });
  });
}
