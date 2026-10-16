import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/repositories/firebase/firebase_contact_relation_repository.dart';

class _Database extends Fake implements FirebaseDatabase {
  final streams = <String, StreamController<DatabaseEvent>>{};
  final reads = <String>[];

  @override
  DatabaseReference ref([String? path]) => _Reference(this, path ?? '');

  void emit(String path, Object? value) => streams[path]!.add(_Event(value));

  Future<void> close() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class _Reference extends Fake implements DatabaseReference {
  final _Database database;
  @override
  final String path;
  _Reference(this.database, this.path);

  @override
  DatabaseReference child(String childPath) =>
      _Reference(database, '$path/$childPath');

  @override
  Stream<DatabaseEvent> get onValue {
    database.reads.add(path);
    return database.streams
        .putIfAbsent(
          path,
          () => StreamController<DatabaseEvent>.broadcast(sync: true),
        )
        .stream;
  }
}

class _Event extends Fake implements DatabaseEvent {
  final Object? value;
  _Event(this.value);
  @override
  DataSnapshot get snapshot => _Snapshot(value);
}

class _Snapshot extends Fake implements DataSnapshot {
  @override
  final Object? value;
  _Snapshot(this.value);
}

const _active = {'status': 'active', 'activeFrom': 1000};
const _indexPath = 'users/contact-test/vehicleIds';
const _relationPath = 'vehicleContacts/vehicle-test/contact-test';
Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  late _Database database;
  late List<Set<String>> results;
  late List<Object> errors;
  late StreamSubscription<Set<String>> subscription;

  setUp(() {
    database = _Database();
    results = [];
    errors = [];
    subscription = FirebaseContactRelationRepository(database: database)
        .watchAuthorizedVehicleIds('contact-test')
        .listen(results.add, onError: errors.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await database.close();
  });

  Future<void> discover() async {
    database.emit(_indexPath, {'vehicle-test': true});
    await _tick();
  }

  Future<void> authorize() async {
    await discover();
    database.emit(_relationPath, _active);
    await _tick();
    expect(results.last, {'vehicle-test'});
  }

  test(
    'map discovers candidates but only the own active relationship authorizes',
    () async {
      await discover();
      expect(results.last, isEmpty);
      database.emit(_relationPath, _active);
      await _tick();
      expect(results.last, {'vehicle-test'});
      expect(database.reads, [_indexPath, _relationPath]);
      expect(() => results.last.add('other'), throwsUnsupportedError);
    },
  );

  for (final index in [
    null,
    ['vehicle-test'],
    'vehicle-test',
    true,
    1,
  ]) {
    test('non-map index $index never authorizes or reads relations', () async {
      database.emit(_indexPath, index);
      await _tick();
      expect(results.last, isEmpty);
      expect(database.reads, [_indexPath]);
    });
  }

  test('only true map entries with safe RTDB keys are candidates', () async {
    database.emit(_indexPath, {
      'vehicle-test': true,
      'false-entry': false,
      'number': 1,
      'string': 'true',
      'nested': {'active': true},
      'bad/path': true,
      '': true,
    });
    await _tick();
    expect(database.reads, [_indexPath, _relationPath]);
    expect(results.last, isEmpty);
  });

  for (final relation in [
    null,
    'active',
    ['active'],
    {'status': 'pending'},
    {'status': 'revoked', 'activeFrom': 1000, 'revokedAt': 2000},
    {'status': 'unknown'},
    {'status': true},
    {'status': 'active'},
    {'status': 'active', 'activeFrom': '1000'},
    {'status': 'active', 'activeFrom': -1},
    {'status': 'active', 'activeFrom': double.nan},
    {'status': 'active', 'activeFrom': double.infinity},
    {..._active, 'revokedAt': 2000},
  ]) {
    test(
      'missing, inactive or inconsistent relation $relation denies',
      () async {
        await discover();
        database.emit(_relationPath, relation);
        await _tick();
        expect(results.last, isEmpty);
      },
    );
  }

  test(
    'revocation invalidates an active result even with a stale index',
    () async {
      await authorize();
      final original = results.last;
      database.emit(_relationPath, {
        'status': 'revoked',
        'activeFrom': 1000,
        'revokedAt': 2000,
      });
      await _tick();
      expect(results.last, isEmpty);
      expect(original, {
        'vehicle-test',
      }); // Previously emitted sets are not mutated.
    },
  );

  test('deleted relationship invalidates active result', () async {
    await authorize();
    database.emit(_relationPath, null);
    await _tick();
    expect(results.last, isEmpty);
  });

  test(
    'index removal invalidates and stops listening to the old relationship',
    () async {
      await authorize();
      database.emit(_indexPath, null);
      await _tick();
      expect(results.last, isEmpty);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
      database.emit(_relationPath, _active);
      await _tick();
      expect(results.last, isEmpty);
    },
  );

  test(
    'a replaced discovery index needs a fresh relationship verification',
    () async {
      await authorize();
      database.emit(_indexPath, {'other-vehicle': true});
      await _tick();
      expect(results.last, isEmpty);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
      database.emit('vehicleContacts/other-vehicle/contact-test', _active);
      await _tick();
      expect(results.last, {'other-vehicle'});
    },
  );

  test(
    'relation read error invalidates before propagating the error',
    () async {
      await authorize();
      final error = StateError('read failed');
      database.streams[_relationPath]!.addError(error);
      await _tick();
      expect(results.last, isEmpty);
      expect(errors, [same(error)]);
    },
  );

  test(
    'index read error invalidates and cancels relation subscriptions',
    () async {
      await authorize();
      final error = StateError('read failed');
      database.streams[_indexPath]!.addError(error);
      await _tick();
      expect(results.last, isEmpty);
      expect(errors, [same(error)]);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
    },
  );

  test(
    'relationship stream completion invalidates the previous result',
    () async {
      await authorize();
      await database.streams[_relationPath]!.close();
      await _tick();
      expect(results.last, isEmpty);
    },
  );

  test('cancelling the session reader releases all subscriptions', () async {
    await authorize();
    await subscription.cancel();
    expect(database.streams[_indexPath]!.hasListener, isFalse);
    expect(database.streams[_relationPath]!.hasListener, isFalse);
  });

  test(
    'another session reads its own relation and cannot reuse the first result',
    () async {
      await authorize();
      await subscription.cancel();
      subscription = FirebaseContactRelationRepository(database: database)
          .watchAuthorizedVehicleIds('other-contact')
          .listen(results.add, onError: errors.add);
      await _tick();
      expect(results.last, isEmpty);
      database.emit('users/other-contact/vehicleIds', {'vehicle-test': true});
      await _tick();
      database.emit('vehicleContacts/vehicle-test/other-contact', {
        'status': 'pending',
      });
      await _tick();
      expect(results.last, isEmpty);
    },
  );
}
