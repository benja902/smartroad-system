import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/models/alert_presentation.dart';
import 'package:smartroad/repositories/firebase/firebase_event_repository.dart';

typedef RawEvents = Map<String, Map<String, dynamic>>;

Map<String, dynamic> event({
  required int seq,
  required int receivedAt,
  Object? ts,
  String? userId,
  String? vehicleId,
  int? cancelledBySeq,
  int? cancelledAt,
  bool? queued,
}) => {
  'id': 'SDA-TEST',
  'seq': seq,
  'type': 'crash',
  'severity': 'grave',
  'receivedAt': receivedAt,
  'ts': ?ts,
  'userId': ?userId,
  'vehicleId': ?vehicleId,
  'cancelledBySeq': ?cancelledBySeq,
  'cancelledAt': ?cancelledAt,
  'queued': ?queued,
};

void main() {
  test(
    'critical index and recent queries deduplicate without losing cancellation',
    () async {
      final recentUser = StreamController<RawEvents>();
      final recentVehicle = StreamController<RawEvents>();
      final critical = StreamController<RawEvents>();
      final merged = StreamIterator<List<AccidentEvent>>(
        FirebaseEventRepository.combineEventStreams(
          recentUser.stream,
          recentVehicle.stream,
          additionalEvents: [critical.stream],
        ),
      );
      final first = merged.moveNext();
      recentUser.add({});
      expect(await first, isTrue);
      final second = merged.moveNext();
      critical.add({
        'SDA-TEST_1': event(seq: 1, userId: 'owner', receivedAt: 1000),
      });
      expect(await second, isTrue);
      final third = merged.moveNext();
      recentVehicle.add({
        'SDA-TEST_1': event(
          seq: 1,
          vehicleId: 'vehicle-1',
          receivedAt: 1000,
          cancelledBySeq: 2,
          cancelledAt: 1100,
        ),
      });
      expect(await third, isTrue);
      expect(merged.current, hasLength(1));
      expect(merged.current.single.cancelledBySeq, 2);
      expect(classify(merged.current.single), AlertPresentation.cancelled);
      await merged.cancel();
      await recentUser.close();
      await recentVehicle.close();
      await critical.close();
    },
  );

  test(
    'combines vehicle-only and historical events, deduplicates and sorts',
    () async {
      final byUser = StreamController<RawEvents>();
      final byVehicle = StreamController<RawEvents>();
      final merged = StreamIterator<List<AccidentEvent>>(
        FirebaseEventRepository.combineEventStreams(
          byUser.stream,
          byVehicle.stream,
        ),
      );

      final first = merged.moveNext();
      byUser.add({
        'SDA-TEST_1': event(
          seq: 1,
          userId: 'owner',
          receivedAt: 3000,
          ts: 'invalid',
        ),
        'SDA-TEST_2': event(
          seq: 2,
          userId: 'owner',
          vehicleId: 'vehicle-1',
          receivedAt: 4000,
          ts: 1000,
          cancelledBySeq: 9,
          cancelledAt: 4500,
          queued: true,
        ),
      });
      expect(await first, isTrue);
      expect(merged.current.map((e) => e.seq), [2, 1]);

      final second = merged.moveNext();
      byVehicle.add({
        'SDA-TEST_2': event(
          seq: 2,
          userId: 'owner',
          vehicleId: 'vehicle-1',
          receivedAt: 4000,
          ts: 1000,
          queued: false,
        ),
        'SDA-TEST_3': event(seq: 3, vehicleId: 'vehicle-1', receivedAt: 2000),
      });
      expect(await second, isTrue);

      final events = merged.current;
      expect(events.map((e) => e.dedupKey), [
        'SDA-TEST_2',
        'SDA-TEST_3',
        'SDA-TEST_1',
      ]);
      expect(events.length, 3);
      expect(events.first.cancelledBySeq, 9);
      expect(events.first.cancelledAt?.millisecondsSinceEpoch, 4500);
      expect(events.first.queued, isTrue);
      expect(events[1].userId, isEmpty);
      expect(events[1].vehicleId, 'vehicle-1');

      await merged.cancel();
      expect(byUser.hasListener, isFalse);
      expect(byVehicle.hasListener, isFalse);
      await byUser.close();
      await byVehicle.close();
    },
  );

  test('keeps cancellation when it arrives from the vehicle query', () async {
    final byUser = StreamController<RawEvents>();
    final byVehicle = StreamController<RawEvents>();
    final merged = StreamIterator<List<AccidentEvent>>(
      FirebaseEventRepository.combineEventStreams(
        byUser.stream,
        byVehicle.stream,
      ),
    );

    final first = merged.moveNext();
    byUser.add({
      'SDA-TEST_4': event(seq: 4, userId: 'owner', receivedAt: 1000),
    });
    expect(await first, isTrue);

    final second = merged.moveNext();
    byVehicle.add({
      'SDA-TEST_4': event(
        seq: 4,
        vehicleId: 'vehicle-1',
        receivedAt: 1000,
        cancelledBySeq: 10,
        cancelledAt: 2000,
      ),
    });
    expect(await second, isTrue);
    expect(merged.current, hasLength(1));
    expect(merged.current.single.cancelledBySeq, 10);

    await merged.cancel();
    await byUser.close();
    await byVehicle.close();
  });

  test(
    'reads historical cancellation beside partial and unknown vehicle events',
    () async {
      final byUser = StreamController<RawEvents>();
      final byVehicle = StreamController<RawEvents>();
      final merged = StreamIterator<List<AccidentEvent>>(
        FirebaseEventRepository.combineEventStreams(
          byUser.stream,
          byVehicle.stream,
        ),
      );

      final first = merged.moveNext();
      byUser.add({
        'SDA-TEST_1': {
          ...event(
            seq: 1,
            userId: 'owner',
            receivedAt: 1000,
            cancelledBySeq: 4,
            cancelledAt: 1200,
          ),
          'acknowledged': true,
          'position': {'fix': true},
        },
      });
      expect(await first, isTrue);

      final second = merged.moveNext();
      byVehicle.add({
        'SDA-TEST_2': {
          'id': 'SDA-TEST',
          'seq': 2,
          'type': 'rollover',
          'receivedAt': 2000,
          'vehicleId': 'vehicle-1',
          'queued': true,
        },
        'SDA-TEST_3': {
          'id': 'SDA-TEST',
          'seq': 3,
          'type': 'future_alarm',
          'severity': 'grave',
          'receivedAt': 3000,
          'vehicleId': 'vehicle-1',
        },
      });
      expect(await second, isTrue);
      final events = merged.current;
      expect(events, hasLength(3));
      expect(classify(events[0]), AlertPresentation.cancelled);
      expect(events[0].position, isNull);
      expect(events[0].acknowledged, isTrue);
      expect(classify(events[1]), AlertPresentation.deferred);
      expect(classify(events[2]), AlertPresentation.technical);
      expect(shouldForceCriticalScreen(events[2]), isFalse);

      await merged.cancel();
      await byUser.close();
      await byVehicle.close();
    },
  );
}
