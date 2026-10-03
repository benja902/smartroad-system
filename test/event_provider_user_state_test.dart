import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_data_seed.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'package:smartroad/state/event_provider.dart';

class ControlledRepository implements EventRepository {
  final streams = <String, StreamController<List<AccidentEvent>>>{};
  final writes = <String>[];
  Completer<void>? pendingWrite;

  @override
  Stream<List<AccidentEvent>> watchEvents(String userId, {String? vehicleId}) =>
      streams
          .putIfAbsent(userId, () => StreamController<List<AccidentEvent>>())
          .stream;

  @override
  Stream<AccidentEvent?> watchCriticalEvent(
    String userId, {
    String? vehicleId,
  }) => const Stream.empty();

  @override
  Future<void> acknowledge(String dedupKey, {required String userId}) {
    writes.add('$userId/$dedupKey');
    return pendingWrite?.future ?? Future.value();
  }

  Future<void> close() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

void main() {
  test(
    'recognition survives logout/login but is not inherited by another user',
    () async {
      final repo = MockEventRepository();
      final original = repo.triggerCrash(vehicleId: MockDataSeed.vehicleId);
      final provider = EventProvider(repo);
      addTearDown(provider.dispose);
      provider.setContext(
        userId: MockDataSeed.userId,
        vehicleId: MockDataSeed.vehicleId,
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.criticalEvent?.dedupKey, original.dedupKey);
      await provider.acknowledge(original.dedupKey);
      await Future<void>.delayed(Duration.zero);
      expect(provider.criticalEvent, isNull);

      provider.setContext(userId: null);
      expect(provider.events, isEmpty);
      await expectLater(
        provider.acknowledge(original.dedupKey),
        throwsStateError,
      );
      provider.setContext(
        userId: 'second-user',
        vehicleId: MockDataSeed.vehicleId,
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.events.single.acknowledged, isFalse);
      expect(provider.criticalEvent?.dedupKey, original.dedupKey);
      provider.setContext(
        userId: MockDataSeed.userId,
        vehicleId: MockDataSeed.vehicleId,
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.events.single.acknowledged, isTrue);
      expect(provider.criticalEvent, isNull);
    },
  );

  test('read/write errors do not mark event attended', () async {
    final repo = ControlledRepository();
    final provider = EventProvider(repo);
    final event = MockEventRepository().triggerCrash();
    provider.setContext(userId: 'owner');
    repo.streams['owner']!.add([event]);
    await Future<void>.delayed(Duration.zero);
    final readError = StateError('read denied');
    repo.streams['owner']!.addError(readError);
    await Future<void>.delayed(Duration.zero);
    expect(provider.error, same(readError));
    expect(provider.criticalEvent?.dedupKey, event.dedupKey);

    repo.pendingWrite = Completer<void>();
    final writeError = StateError('write denied');
    final future = provider.acknowledge(event.dedupKey);
    final expectation = expectLater(future, throwsA(same(writeError)));
    repo.pendingWrite!.completeError(writeError);
    await expectation;
    expect(provider.error, same(writeError));
    expect(provider.events.single.acknowledged, isFalse);
    expect(provider.criticalEvent?.dedupKey, event.dedupKey);
    provider.dispose();
    await repo.close();
  });

  test('pending write captures uid and stale completion does not affect new session', () async {
    final repo = ControlledRepository();
    final provider = EventProvider(repo);
    provider.setContext(userId: 'owner');
    repo.pendingWrite = Completer<void>();
    final error = StateError('old write denied');
    final write = provider.acknowledge('SDA-TEST_1');
    final expectation = expectLater(write, throwsA(same(error)));
    provider.setContext(userId: 'second-user');
    repo.pendingWrite!.completeError(error);
    await expectation;
    expect(repo.writes, ['owner/SDA-TEST_1']);
    expect(provider.error, isNull);
    expect(repo.streams['owner']!.hasListener, isFalse);
    provider.dispose();
    await repo.close();
  });
}
