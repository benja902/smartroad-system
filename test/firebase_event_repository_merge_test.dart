import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
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
};

void main() {
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
}
