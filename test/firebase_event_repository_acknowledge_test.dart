import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/repositories/firebase/firebase_event_repository.dart';

class TestDatabase extends Fake implements FirebaseDatabase {
  final writes = <String, Map<String, Object?>>{};
  final streams = <String, StreamController<DatabaseEvent>>{};
  final queryLimits = <String, int>{};
  final values = <String, Object?>{};
  Object? writeError;

  @override
  DatabaseReference ref([String? path]) => TestReference(this, path ?? '');

  void emit(String key, Object? value) {
    streams[key]!.add(TestEvent(value));
  }

  Future<void> close() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class TestReference extends Fake implements DatabaseReference {
  final TestDatabase database;
  @override
  final String path;
  final String? filter;

  TestReference(this.database, this.path, [this.filter]);

  @override
  DatabaseReference child(String childPath) =>
      TestReference(database, '$path/$childPath');

  @override
  Query orderByChild(String childPath) =>
      TestReference(database, path, childPath);

  @override
  Query orderByKey() => TestReference(database, path, 'key');

  @override
  Query equalTo(Object? value, {String? key}) =>
      TestReference(database, path, '$filter=$value');

  @override
  Query limitToLast(int limit) {
    database.queryLimits['$path/$filter'] = limit;
    return this;
  }

  @override
  Stream<DatabaseEvent> get onValue => database.streams
      .putIfAbsent(
        filter == null ? path : '$path/$filter',
        () => StreamController<DatabaseEvent>(),
      )
      .stream;

  @override
  Future<void> update(Map<String, Object?> value) async {
    if (database.writeError case final error?) throw error;
    database.writes[path] = value;
  }

  @override
  Future<DataSnapshot> get() async => TestSnapshot(database.values[path]);
}

class TestEvent extends Fake implements DatabaseEvent {
  final Object? value;
  TestEvent(this.value);
  @override
  DataSnapshot get snapshot => TestSnapshot(value);
}

class TestSnapshot extends Fake implements DataSnapshot {
  @override
  final Object? value;
  TestSnapshot(this.value);
  @override
  bool get exists => value != null;
}

void main() {
  test(
    'writes only personal state using session uid and original eventKey',
    () async {
      final database = TestDatabase();
      final repo = FirebaseEventRepository(database: database);
      await repo.acknowledge('SDA-TEST_1', userId: 'owner');
      expect(database.writes, {
        'userIncidentState/owner/SDA-TEST_1': {'acknowledged': true},
      });
      expect(repo.readUserIncidentState, isTrue);
    },
  );

  test('rejects empty uid without writing', () async {
    final database = TestDatabase();
    final repo = FirebaseEventRepository(database: database);
    await expectLater(
      repo.acknowledge('SDA-TEST_1', userId: ''),
      throwsStateError,
    );
    expect(database.writes, isEmpty);
  });

  test('write error propagates without global write or fallback', () async {
    final database = TestDatabase();
    final error = StateError('permission denied');
    database.writeError = error;
    final repo = FirebaseEventRepository(database: database);
    await expectLater(
      repo.acknowledge('SDA-TEST_1', userId: 'owner'),
      throwsA(same(error)),
    );
    expect(database.writes, isEmpty);
  });

  test(
    'default read listens to personal state and cancels both sources',
    () async {
      final database = TestDatabase();
      final repo = FirebaseEventRepository(database: database);
      final output = <List<AccidentEvent>>[];
      final subscription = repo.watchEvents('owner').listen(output.add);
      database.values['events/SDA-TEST_1'] = {
        'id': 'SDA-TEST',
        'seq': 1,
        'type': 'crash',
        'severity': 'grave',
        'userId': 'owner',
        'vehicleId': 'vehicle-1',
        'receivedAt': 1000,
      };
      database.emit('eventReadIndex/users/owner/key', {
        '0000000000001000_a': {'eventKey': 'SDA-TEST_1'},
      });
      await Future<void>.delayed(Duration.zero);
      expect(output, isEmpty);
      database.emit('userIncidentState/owner', {
        'SDA-TEST_1': {'acknowledged': true},
      });
      await Future<void>.delayed(Duration.zero);
      expect(output.single.single.acknowledged, isTrue);
      await subscription.cancel();
      expect(database.streams.values.every((s) => !s.hasListener), isTrue);
      await database.close();
    },
  );

  test('owner uses bounded recent and critical queries without losing an older emergency', () async {
    final database = TestDatabase();
    final repo = FirebaseEventRepository(database: database);
    final output = <List<AccidentEvent>>[];
    final subscription = repo
        .watchEvents('owner', vehicleId: 'vehicle-1')
        .listen(output.add);
    expect(database.queryLimits, {
      'eventReadIndex/users/owner/key': FirebaseEventRepository.eventQueryLimit,
      'eventReadIndex/vehicles/vehicle-1/key': FirebaseEventRepository.eventQueryLimit,
      'events/criticalLegacyUserId=owner':
          FirebaseEventRepository.eventQueryLimit,
      'events/criticalVehicleId=vehicle-1':
          FirebaseEventRepository.eventQueryLimit,
    });
    database.emit('eventReadIndex/users/owner/key', {});
    database.values['events/SDA-TEST_101'] = {
        'id': 'SDA-TEST',
        'seq': 101,
        'type': 'crash',
        'severity': 'leve',
        'receivedAt': 2000,
        'vehicleId': 'vehicle-1',
      };
    database.emit('eventReadIndex/vehicles/vehicle-1/key', {
      '0000000000002000_b': {'eventKey': 'SDA-TEST_101'},
    });
    database.emit('events/criticalLegacyUserId=owner', {
      'SDA-TEST_1': {
        'id': 'SDA-TEST',
        'seq': 1,
        'type': 'sos',
        'receivedAt': 1000,
        'userId': 'owner',
      },
    });
    database.emit('events/criticalVehicleId=vehicle-1', {});
    database.emit('userIncidentState/owner', {});
    await Future<void>.delayed(Duration.zero);
    expect(output.last.map((event) => event.seq), [1, 101]);
    expect(output.last.first.cancelledBySeq, isNull);
    database.emit('userIncidentState/owner', {
      'SDA-TEST_1': {'acknowledged': true},
    });
    await Future<void>.delayed(Duration.zero);
    expect(output.last.first.acknowledged, isTrue);
    await subscription.cancel();
    await database.close();
  });

  test('pointer refresh reads the cancelled canonical event', () async {
    final database = TestDatabase();
    final repo = FirebaseEventRepository(database: database, readUserIncidentState: false);
    final output = <List<AccidentEvent>>[];
    final subscription = repo.watchEvents('owner').listen(output.add);
    database.values['events/SDA-TEST_1'] = {
      'id': 'SDA-TEST', 'seq': 1, 'type': 'crash',
      'receivedAt': 1000, 'userId': 'owner',
    };
    database.emit('events/criticalLegacyUserId=owner', {});
    database.emit('eventReadIndex/users/owner/key', {
      '0000000000001000_a': {'eventKey': 'SDA-TEST_1', 'digest': 'before'},
    });
    await Future<void>.delayed(Duration.zero);
    expect(output.last.single.cancelledBySeq, isNull);
    database.values['events/SDA-TEST_1'] = {
      'id': 'SDA-TEST', 'seq': 1, 'type': 'crash',
      'receivedAt': 1000, 'userId': 'owner',
      'cancelledBySeq': 2, 'cancelledAt': 2000,
    };
    database.emit('eventReadIndex/users/owner/key', {
      '0000000000001000_a': {'eventKey': 'SDA-TEST_1', 'digest': 'after'},
    });
    await Future<void>.delayed(Duration.zero);
    expect(output.last.single.cancelledBySeq, 2);
    await subscription.cancel();
    await database.close();
  });
}
