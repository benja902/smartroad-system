import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event_type.dart';
import 'package:smartroad/models/accident_severity.dart';
import 'package:smartroad/models/alert_presentation.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';

void main() {
  group('MockEventRepository', () {
    test('triggerCrash creates a live, non-queued event that forces the critical screen when grave', () {
      final repo = MockEventRepository();
      final event = repo.triggerCrash(severity: AccidentSeverity.grave);

      expect(event.type, AccidentEventType.crash);
      expect(event.severity, AccidentSeverity.grave);
      expect(event.queued, isFalse);
      expect(shouldForceCriticalScreen(event), isTrue);
    });

    test('triggerCrash with queued:true never forces the critical screen regardless of severity', () async {
      final repo = MockEventRepository();
      repo.triggerCrash(severity: AccidentSeverity.grave, queued: true);

      final critical = await repo.watchCriticalEvent('user-1').first;
      expect(critical, isNull);
    });

    test('triggerSos forces the critical screen with no severity involved', () {
      final repo = MockEventRepository();
      final event = repo.triggerSos();

      expect(event.type, AccidentEventType.sos);
      expect(shouldForceCriticalScreen(event), isTrue);
    });

    test('triggerCancel has its own seq, distinct from cancelsSeq, and closes the original event', () async {
      final repo = MockEventRepository();
      final original = repo.triggerCrash(severity: AccidentSeverity.grave);

      repo.triggerCancel(original.seq);

      final events = await repo.watchEvents('user-1').first;
      final cancelEvent = events.firstWhere((e) => e.type == AccidentEventType.cancel);
      expect(cancelEvent.seq, isNot(original.seq));
      expect(cancelEvent.cancelsSeq, original.seq);

      final updatedOriginal = events.firstWhere((e) => e.seq == original.seq);
      expect(updatedOriginal.cancelledBySeq, cancelEvent.seq);

      final critical = await repo.watchCriticalEvent('user-1').first;
      expect(critical, isNull);
    });

    test('a cancel that arrives referencing an unknown seq does not throw', () {
      final repo = MockEventRepository();
      expect(() => repo.triggerCancel(999), returnsNormally);
    });

    test('acknowledge stops the event from forcing the critical screen without marking it cancelled', () async {
      final repo = MockEventRepository();
      final event = repo.triggerCrash(severity: AccidentSeverity.grave);

      await repo.acknowledge(event.dedupKey);

      final events = await repo.watchEvents('user-1').first;
      final updated = events.firstWhere((e) => e.seq == event.seq);
      expect(updated.acknowledged, isTrue);
      expect(updated.cancelledBySeq, isNull);
      expect(classify(updated), AlertPresentation.attended);

      final critical = await repo.watchCriticalEvent('user-1').first;
      expect(critical, isNull);
    });

    test('triggerTechnical produces events classified as technical, never critical', () {
      final repo = MockEventRepository();
      for (final type in [
        AccidentEventType.test,
        AccidentEventType.powerLoss,
        AccidentEventType.lowBattery,
        AccidentEventType.booted,
      ]) {
        final event = repo.triggerTechnical(type);
        expect(classify(event), AlertPresentation.technical);
        expect(shouldForceCriticalScreen(event), isFalse);
      }
    });

    test('watchEvents replays current state to new subscribers', () async {
      final repo = MockEventRepository();
      repo.triggerCrash(severity: AccidentSeverity.leve);
      repo.triggerCrash(severity: AccidentSeverity.moderado);

      final events = await repo.watchEvents('user-1').first;
      expect(events, hasLength(2));
    });
  });
}
