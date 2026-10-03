import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/repositories/mock/mock_data_seed.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';

void main() {
  test('two users see independent state and critical presentation', () async {
    final repo = MockEventRepository(readUserIncidentState: true);
    final original = repo.triggerCrash(vehicleId: 'vehicle-test');
    final ownerEvents = <List<AccidentEvent>>[];
    final otherEvents = <List<AccidentEvent>>[];
    final ownerSubscription = repo
        .watchEvents(MockDataSeed.userId, vehicleId: 'vehicle-test')
        .listen(ownerEvents.add);
    final otherSubscription = repo
        .watchEvents('second-user', vehicleId: 'vehicle-test')
        .listen(otherEvents.add);
    await Future<void>.delayed(Duration.zero);

    await repo.acknowledge(original.dedupKey, userId: MockDataSeed.userId);
    await Future<void>.delayed(Duration.zero);
    expect(ownerEvents.last.single.acknowledged, isTrue);
    expect(otherEvents.last.single.acknowledged, isFalse);
    expect(original.acknowledged, isFalse);
    expect(
      await repo
          .watchCriticalEvent(MockDataSeed.userId, vehicleId: 'vehicle-test')
          .first,
      isNull,
    );
    expect(
      (await repo
              .watchCriticalEvent('second-user', vehicleId: 'vehicle-test')
              .first)
          ?.dedupKey,
      original.dedupKey,
    );

    repo.triggerCancel(original.seq);
    await Future<void>.delayed(Duration.zero);
    final owner = ownerEvents.last.firstWhere((e) => e.seq == original.seq);
    final other = otherEvents.last.single;
    expect(owner.cancelledBySeq, isNotNull);
    expect(other.cancelledBySeq, owner.cancelledBySeq);
    expect(other.cancelledAt, owner.cancelledAt);
    expect(owner.acknowledged, isTrue);
    expect(other.acknowledged, isFalse);
    expect(
      await repo
          .watchCriticalEvent('second-user', vehicleId: 'vehicle-test')
          .first,
      isNull,
    );
    await ownerSubscription.cancel();
    await otherSubscription.cancel();
  });

  test('historical recognition is personal and explicit false wins', () async {
    final repo = MockEventRepository(readUserIncidentState: true);
    final original = repo.triggerSos();
    await repo.acknowledge(original.dedupKey, userId: MockDataSeed.userId);
    expect(
      (await repo.watchEvents(MockDataSeed.userId).first).single.acknowledged,
      isTrue,
    );
    expect(
      (await repo.watchEvents('second-user').first).single.acknowledged,
      isFalse,
    );
    repo.seedUserIncidentState(
      MockDataSeed.userId,
      original.dedupKey,
      acknowledged: false,
    );
    expect(
      (await repo.watchEvents(MockDataSeed.userId).first).single.acknowledged,
      isFalse,
    );
  });

  test('re-subscribing retains personal state and event ordering', () async {
    final repo = MockEventRepository(readUserIncidentState: true);
    final queued = repo.triggerCrash(queued: true, vehicleId: 'vehicle-test');
    final live = repo.triggerSos(vehicleId: 'vehicle-test');
    repo.seedUserIncidentState(
      'second-user',
      live.dedupKey,
      acknowledged: true,
    );
    for (var i = 0; i < 2; i++) {
      final events = await repo
          .watchEvents('second-user', vehicleId: 'vehicle-test')
          .first;
      expect(events.map((e) => e.dedupKey), [queued.dedupKey, live.dedupKey]);
      expect(events.map((e) => e.acknowledged), [false, true]);
    }
  });

  test('default DEV behavior uses personal acknowledgment', () async {
    final repo = MockEventRepository();
    final original = repo.triggerSos();
    expect(
      (await repo.watchEvents(MockDataSeed.userId).first).single.acknowledged,
      isFalse,
    );
    await repo.acknowledge(original.dedupKey, userId: MockDataSeed.userId);
    expect(
      (await repo.watchEvents(MockDataSeed.userId).first).single.acknowledged,
      isTrue,
    );
    expect(original.acknowledged, isFalse);
    expect(
      (await repo.watchEvents('second-user').first).single.acknowledged,
      isFalse,
    );
  });
}
