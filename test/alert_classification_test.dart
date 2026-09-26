import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/models/accident_event_type.dart';
import 'package:smartroad/models/accident_severity.dart';
import 'package:smartroad/models/alert_presentation.dart';

AccidentEvent _event({
  AccidentEventType type = AccidentEventType.crash,
  AccidentSeverity severity = AccidentSeverity.grave,
  bool queued = false,
  bool acknowledged = false,
  int? cancelledBySeq,
}) {
  return AccidentEvent(
    deviceId: 'SDA-TEST',
    type: type,
    seq: 1,
    severity: severity,
    queued: queued,
    acknowledged: acknowledged,
    cancelledBySeq: cancelledBySeq,
    receivedAt: DateTime.now(),
    userId: 'user-1',
  );
}

void main() {
  group('classify() truth table', () {
    test('technical event types never touch severity', () {
      for (final type in [
        AccidentEventType.test,
        AccidentEventType.powerLoss,
        AccidentEventType.lowBattery,
        AccidentEventType.booted,
      ]) {
        expect(classify(_event(type: type, severity: AccidentSeverity.grave)), AlertPresentation.technical);
      }
    });

    test('cancel type is its own category, never mixed with severity', () {
      expect(classify(_event(type: AccidentEventType.cancel)), AlertPresentation.cancellation);
    });

    test('cancelledBySeq wins over everything else for crash/rollover/sos', () {
      expect(
        classify(_event(severity: AccidentSeverity.grave, cancelledBySeq: 99)),
        AlertPresentation.cancelled,
      );
      expect(
        classify(_event(type: AccidentEventType.sos, cancelledBySeq: 99)),
        AlertPresentation.cancelled,
      );
    });

    test('acknowledged wins over queued/severity but not over cancelledBySeq', () {
      expect(classify(_event(acknowledged: true, severity: AccidentSeverity.grave)), AlertPresentation.attended);
      expect(
        classify(_event(acknowledged: true, cancelledBySeq: 5, severity: AccidentSeverity.grave)),
        AlertPresentation.cancelled,
      );
    });

    test('queued grave crash is DIFERIDO, never activeEmergency', () {
      expect(
        classify(_event(severity: AccidentSeverity.grave, queued: true)),
        AlertPresentation.deferred,
      );
    });

    test('sos forces activeEmergency regardless of severity value', () {
      expect(classify(_event(type: AccidentEventType.sos, severity: AccidentSeverity.none)), AlertPresentation.activeEmergency);
    });

    test('grave crash/rollover forces activeEmergency', () {
      expect(classify(_event(type: AccidentEventType.crash, severity: AccidentSeverity.grave)), AlertPresentation.activeEmergency);
      expect(classify(_event(type: AccidentEventType.rollover, severity: AccidentSeverity.grave)), AlertPresentation.activeEmergency);
    });

    test('moderado is attention, not activeEmergency', () {
      expect(classify(_event(severity: AccidentSeverity.moderado)), AlertPresentation.attention);
    });

    test('leve/none/unknown severity is informative, never forces the screen', () {
      expect(classify(_event(severity: AccidentSeverity.leve)), AlertPresentation.informative);
      expect(classify(_event(severity: AccidentSeverity.none)), AlertPresentation.informative);
      expect(classify(_event(severity: AccidentSeverity.unknown)), AlertPresentation.informative);
    });
  });

  group('shouldForceCriticalScreen()', () {
    test('true only for live, non-cancelled, non-acknowledged grave/sos', () {
      expect(shouldForceCriticalScreen(_event(severity: AccidentSeverity.grave)), isTrue);
      expect(shouldForceCriticalScreen(_event(type: AccidentEventType.sos)), isTrue);
    });

    test('false for queued grave — already happened, must not force the screen', () {
      expect(shouldForceCriticalScreen(_event(severity: AccidentSeverity.grave, queued: true)), isFalse);
    });

    test('false once cancelled or acknowledged', () {
      expect(shouldForceCriticalScreen(_event(severity: AccidentSeverity.grave, cancelledBySeq: 1)), isFalse);
      expect(shouldForceCriticalScreen(_event(severity: AccidentSeverity.grave, acknowledged: true)), isFalse);
    });

    test('false for moderado/leve/technical/cancel', () {
      expect(shouldForceCriticalScreen(_event(severity: AccidentSeverity.moderado)), isFalse);
      expect(shouldForceCriticalScreen(_event(severity: AccidentSeverity.leve)), isFalse);
      expect(shouldForceCriticalScreen(_event(type: AccidentEventType.test)), isFalse);
      expect(shouldForceCriticalScreen(_event(type: AccidentEventType.cancel)), isFalse);
    });
  });
}
