import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';

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
      expect(event.receivedAt.millisecondsSinceEpoch, 1760000000000);
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
}
