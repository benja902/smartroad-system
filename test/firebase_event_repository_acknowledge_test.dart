import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/repositories/firebase/firebase_event_repository.dart';

class TestDatabase extends Fake implements FirebaseDatabase {
  final writes = <String, Map<String, Object?>>{};
  final streams = <String, StreamController<DatabaseEvent>>{};
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
  Query equalTo(Object? value, {String? key}) =>
      TestReference(database, path, '$filter=$value');

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
      database.emit('events/userId=owner', {
        'SDA-TEST_1': {
          'id': 'SDA-TEST',
          'seq': 1,
          'type': 'crash',
          'severity': 'grave',
          'userId': 'owner',
          'receivedAt': 1000,
        },
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
}
