import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/repositories/firebase/firebase_event_repository.dart';

AccidentEvent event({String? vehicleId, String userId = 'owner'}) =>
    AccidentEvent.fromJson('SDA-TEST_1', {
      'id': 'SDA-TEST',
      'seq': 1,
      'type': 'crash',
      'severity': 'grave',
      'receivedAt': 1000,
      'userId': userId,
      'vehicleId': vehicleId,
      'acknowledged': true,
      'cancelledBySeq': 2,
      'cancelledAt': 2000,
    });

Future<AccidentEvent> project(AccidentEvent source, Object? state) async {
  final result = await FirebaseEventRepository.combineUserIncidentState(
    Stream.value([source]),
    Stream.value({'SDA-TEST_1': state}),
    'owner',
  ).single;
  return result.single;
}

void main() {
  test('personal false overrides global true without mutating event', () async {
    final source = event();
    final result = await project(source, {'acknowledged': false});
    expect(result.acknowledged, isFalse);
    expect(source.acknowledged, isTrue);
    expect(result.cancelledBySeq, source.cancelledBySeq);
    expect(result.cancelledAt, source.cancelledAt);
    expect(result.receivedAt, source.receivedAt);
  });

  test('personal true is used for vehicle events', () async {
    final result = await project(event(vehicleId: 'v'), {'acknowledged': true});
    expect(result.acknowledged, isTrue);
  });

  test('absent state preserves historical owner acknowledgment', () async {
    expect((await project(event(), null)).acknowledged, isTrue);
  });

  test(
    'global acknowledgment is not inherited by other users or new events',
    () async {
      expect(
        (await project(event(userId: 'other'), null)).acknowledged,
        isFalse,
      );
      expect(
        (await project(event(vehicleId: 'v'), null)).acknowledged,
        isFalse,
      );
    },
  );

  test('malformed personal value uses controlled legacy fallback', () async {
    for (final state in [
      false,
      'invalid',
      {'acknowledged': 'true'},
      <String, dynamic>{},
    ]) {
      expect((await project(event(), state)).acknowledged, isTrue);
      expect(
        (await project(event(vehicleId: 'v'), state)).acknowledged,
        isFalse,
      );
    }
  });

  test(
    'waits for both sources, updates, keeps order and cancels subscriptions',
    () async {
      final events = StreamController<List<AccidentEvent>>();
      final states = StreamController<Map<String, dynamic>>();
      final output = <List<AccidentEvent>>[];
      final subscription = FirebaseEventRepository.combineUserIncidentState(
        events.stream,
        states.stream,
        'owner',
      ).listen(output.add);
      final source = event();
      events.add([source, source.copyWith(acknowledged: false)]);
      await Future<void>.delayed(Duration.zero);
      expect(output, isEmpty);
      states.add({});
      await Future<void>.delayed(Duration.zero);
      expect(output.single.map((e) => e.acknowledged), [true, false]);
      states.add({
        'SDA-TEST_1': {'acknowledged': false},
      });
      await Future<void>.delayed(Duration.zero);
      expect(output.last.map((e) => e.acknowledged), [false, false]);
      expect(output, hasLength(2));
      await subscription.cancel();
      expect(events.hasListener, isFalse);
      expect(states.hasListener, isFalse);
      await events.close();
      await states.close();
    },
  );

  test(
    'read errors propagate instead of acting as absent personal state',
    () async {
      final error = StateError('permission denied');
      final stream = FirebaseEventRepository.combineUserIncidentState(
        Stream.value([event()]),
        Stream<Map<String, dynamic>>.error(error),
        'owner',
      );
      await expectLater(
        stream,
        emitsInOrder([emitsError(same(error)), emitsDone]),
      );
    },
  );
}
