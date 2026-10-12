import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/models/accident_event_type.dart';
import 'package:smartroad/models/alert_presentation.dart';

Map<String, dynamic> _eventJson({
  Object? ts,
  bool includeTs = true,
  String? vehicleId,
}) {
  return {
    'id': 'SDA-TEST',
    'type': 'sos',
    'seq': 7,
    if (includeTs) 'ts': ts,
    'receivedAt': 1760000000000,
    'userId': 'user-test',
    'vehicleId': ?vehicleId,
  };
}

void main() {
  group('AccidentEvent timestamp compatibility', () {
    test('absent server times remain absent, including through personal state copy', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', {
        'id': 'SDA-TEST', 'seq': 7, 'type': 'sos', 'userId': 'owner',
      });
      expect(event.receivedAt, isNull);
      expect(event.updatedAt, isNull);
      expect(event.copyWith(acknowledged: true).toJson()['receivedAt'], isNull);
    });

    test('reads distinct first receipt and material update times', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', {
        ..._eventJson(), 'updatedAt': 1760000001000,
      });
      expect(event.receivedAt?.millisecondsSinceEpoch, 1760000000000);
      expect(event.updatedAt?.millisecondsSinceEpoch, 1760000001000);
      expect(event.copyWith(acknowledged: true).updatedAt, event.updatedAt);
    });
    test('reads a valid ISO 8601 string', () {
      const rawTimestamp = '2026-08-22T15:55:27.000Z';

      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(ts: rawTimestamp),
      );

      expect(event.ts, DateTime.parse(rawTimestamp));
    });

    test('reads a numeric timestamp as epoch milliseconds', () {
      const rawTimestamp = 1787414127000;

      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(ts: rawTimestamp),
      );

      expect(event.ts?.millisecondsSinceEpoch, rawTimestamp);
    });

    test('numeric zero is not presented as a known device time', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', _eventJson(ts: 0));
      expect(event.ts, isNull);
      expect(event.ts ?? event.receivedAt, event.receivedAt);
    });

    test('keeps ts null when the value is null', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', _eventJson(ts: null));

      expect(event.ts, isNull);
    });

    test('keeps ts null when the field is absent', () {
      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(includeTs: false),
      );

      expect(event.ts, isNull);
    });

    test('keeps ts null for an invalid string', () {
      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(ts: 'not-a-date'),
      );

      expect(event.ts, isNull);
    });

    test('keeps ts null for an unexpected type', () {
      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(ts: {'unexpected': true}),
      );

      expect(event.ts, isNull);
    });

    test('receivedAt remains the fallback when ts is invalid', () {
      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(ts: 'invalid'),
      );

      expect(event.ts, isNull);
      expect(event.ts ?? event.receivedAt, event.receivedAt);
      expect(event.receivedAt?.millisecondsSinceEpoch, 1760000000000);
    });
  });

  group('AccidentEvent vehicleId compatibility', () {
    test('reads a historical event without vehicleId', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', _eventJson());

      expect(event.vehicleId, isNull);
      expect(event.userId, 'user-test');
    });

    test('reads a new event with vehicleId', () {
      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(vehicleId: 'vehicle-test'),
      );

      expect(event.vehicleId, 'vehicle-test');
    });

    test('preserves userId alongside vehicleId', () {
      final event = AccidentEvent.fromJson(
        'SDA-TEST_7',
        _eventJson(vehicleId: 'vehicle-test'),
      );
      final updated = event.copyWith(acknowledged: true);

      expect(updated.userId, 'user-test');
      expect(updated.vehicleId, 'vehicle-test');
      expect(updated.toJson()['userId'], 'user-test');
      expect(updated.toJson()['vehicleId'], 'vehicle-test');
    });

    test(
      'deserializes both historical and new event shapes without errors',
      () {
        expect(
          () => AccidentEvent.fromJson('SDA-TEST_7', _eventJson()),
          returnsNormally,
        );
        expect(
          () => AccidentEvent.fromJson(
            'SDA-TEST_7',
            _eventJson(vehicleId: 'vehicle-test'),
          ),
          returnsNormally,
        );
      },
    );
  });

  group('partial and historical incident reading', () {
    test('reads a valid partial event without optional blocks or severity', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', {
        'id': 'SDA-TEST', 'seq': 7, 'type': 'rollover',
        'receivedAt': 1760000000000, 'vehicleId': 'vehicle-test',
      });
      expect(event.position, isNull);
      expect(event.detection, isNull);
      expect(event.device, isNull);
      expect(event.ts, isNull);
      expect(event.queued, isFalse);
      expect(classify(event), AlertPresentation.informative);
    });

    test('drops malformed optional historical blocks without losing the incident', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', {
        ..._eventJson(),
        'position': {'fix': true, 'lat': 91, 'lon': 1},
        'detection': {'peak_g': 'bad'},
        'device': {'battery_v': 'bad'},
        'cancelledBySeq': 8,
        'cancelledAt': 1760000001000,
        'acknowledged': true,
      });
      expect(event.position, isNull);
      expect(event.detection, isNull);
      expect(event.device, isNull);
      expect(event.cancelledBySeq, 8);
      expect(event.cancelledAt?.millisecondsSinceEpoch, 1760000001000);
      expect(event.acknowledged, isTrue);
      expect(classify(event), AlertPresentation.cancelled);
    });

    test('keeps compatible partial optional blocks', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', {
        ..._eventJson(),
        'position': {'lat': -9.9, 'lon': -76.2},
        'detection': {'duration_ms': 62},
        'device': {'battery_v': 4.02},
      });
      expect(event.position?.latitude, -9.9);
      expect(event.position?.fix, isFalse);
      expect(event.detection?.durationMs, 62);
      expect(event.device?.batteryV, 4.02);
    });

    test('unknown grave type is read without becoming a critical accident', () {
      final event = AccidentEvent.fromJson('SDA-TEST_7', {
        ..._eventJson(), 'type': 'future_alarm', 'severity': 'grave',
      });
      expect(event.type, AccidentEventType.unknown);
      expect(classify(event), AlertPresentation.technical);
      expect(shouldForceCriticalScreen(event), isFalse);
    });
  });
}
