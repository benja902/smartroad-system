import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/repositories/firebase/firebase_contact_relation_repository.dart';

class _User extends Fake implements fb_auth.User {
  @override
  final String uid;
  _User(this.uid);
}

class _Auth extends Fake implements fb_auth.FirebaseAuth {
  fb_auth.User? _current = _User('contact-test');
  final changes = StreamController<fb_auth.User?>.broadcast(sync: true);

  @override
  fb_auth.User? get currentUser => _current;

  @override
  Stream<fb_auth.User?> authStateChanges() async* {
    yield _current;
    yield* changes.stream;
  }

  void changeUid(String? uid) {
    _current = uid == null ? null : _User(uid);
    changes.add(_current);
  }

  @override
  Future<void> signOut() async => changeUid(null);
}

class _Database extends Fake implements FirebaseDatabase {
  final streams = <String, StreamController<DatabaseEvent>>{};
  final reads = <String>[];
  final callbacks = <String, List<void Function(DatabaseEvent)>>{};

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
    final stream = database.streams
        .putIfAbsent(
          path,
          () => StreamController<DatabaseEvent>.broadcast(sync: true),
        )
        .stream;
    return _ObservedStream(database, path, stream);
  }
}

// Retain callbacks so tests can simulate a native response already in flight
// when its subscription was cancelled. Normal events still use real streams.
class _ObservedStream extends Stream<DatabaseEvent> {
  final _Database database;
  final String path;
  final Stream<DatabaseEvent> stream;
  _ObservedStream(this.database, this.path, this.stream);

  @override
  StreamSubscription<DatabaseEvent> listen(
    void Function(DatabaseEvent)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (onData != null) {
      database.callbacks.putIfAbsent(path, () => []).add(onData);
    }
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
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
  late _Auth auth;
  late _Database database;
  late List<Set<String>> results;
  late List<Object> errors;
  late StreamSubscription<Set<String>> subscription;
  StreamSubscription<bool>? invitationSubscription;
  late List<bool> invitations;
  late List<Object> invitationErrors;

  setUp(() async {
    auth = _Auth();
    database = _Database();
    results = [];
    errors = [];
    subscription = FirebaseContactRelationRepository(
      auth: auth,
      database: database,
    ).watchAuthorizedVehicleIds().listen(results.add, onError: errors.add);
    await _tick();
  });

  tearDown(() async {
    await invitationSubscription?.cancel();
    invitationSubscription = null;
    await subscription.cancel();
    await database.close();
    await auth.changes.close();
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

  Future<void> watchInvitation([String reference = 'vehicle-test']) async {
    // Switch the fixture from the active reader to the invitation reader.
    // Session tests below never cancel the consumer during identity changes.
    await subscription.cancel();
    database.reads.clear();
    invitations = [];
    invitationErrors = [];
    invitationSubscription =
        FirebaseContactRelationRepository(auth: auth, database: database)
            .watchPendingInvitation(reference)
            .listen(invitations.add, onError: invitationErrors.add);
    await _tick();
  }

  test(
    'pending invitation reads only the own relation without a discovery index',
    () async {
      await watchInvitation();
      expect(invitations.last, isFalse);
      expect(database.reads, [_relationPath]);
      database.emit(_relationPath, {
        'status': 'pending',
        'privateMetadata': 'not exposed',
      });
      await _tick();
      expect(invitations.last, isTrue);
      expect(results, everyElement(isEmpty));
      expect(database.reads, [_relationPath]);
    },
  );

  for (final value in [
    null,
    'pending',
    ['pending'],
    {'status': 'unknown'},
    {'status': true},
    _active,
    {'status': 'revoked'},
    {'status': 'pending', 'activeFrom': 1000},
    {'status': 'pending', 'revokedAt': 2000},
  ]) {
    test(
      'pending invitation rejects missing, non-pending or inconsistent value $value',
      () async {
        await watchInvitation();
        database.emit(_relationPath, value);
        await _tick();
        expect(invitations.last, isFalse);
      },
    );
  }

  test(
    'pending invitation rejects invalid references without RTDB reads',
    () async {
      await watchInvitation('bad/path');
      expect(invitations.last, isFalse);
      expect(database.reads, isEmpty);
    },
  );

  test('pending invitation waits for authentication and uses only the signed-in UID', () async {
    await auth.signOut();
    await watchInvitation();
    expect(invitations.last, isFalse);
    expect(database.reads, isEmpty);
    auth.changeUid('contact-test');
    await _tick();
    expect(database.reads, [_relationPath]);
    database.emit(_relationPath, {'status': 'pending'});
    await _tick();
    expect(invitations.last, isTrue);
  });

  test(
    'pending invitation disappears when removed or its status changes',
    () async {
      await watchInvitation();
      for (final value in [
        null,
        _active,
        {'status': 'revoked'},
      ]) {
        database.emit(_relationPath, {'status': 'pending'});
        await _tick();
        expect(invitations.last, isTrue);
        database.emit(_relationPath, value);
        await _tick();
        expect(invitations.last, isFalse);
      }
    },
  );

  test(
    'pending invitation read error clears a previously visible proposal',
    () async {
      await watchInvitation();
      database.emit(_relationPath, {'status': 'pending'});
      await _tick();
      expect(invitations.last, isTrue);
      final error = StateError('read denied');
      database.streams[_relationPath]!.addError(error);
      await _tick();
      expect(invitations.last, isFalse);
      expect(invitationErrors, [same(error)]);
    },
  );

  test(
    'pending invitation logout cancels the old read and ignores late responses',
    () async {
      await watchInvitation();
      final oldResponse = database.callbacks[_relationPath]!.single;
      database.emit(_relationPath, {'status': 'pending'});
      await _tick();
      expect(invitations.last, isTrue);
      await auth.signOut();
      await _tick();
      expect(invitations.last, isFalse);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
      oldResponse(_Event({'status': 'pending'}));
      await _tick();
      expect(invitations.last, isFalse);
    },
  );

  test('pending invitation UID change verifies the new recipient and ignores old callbacks', () async {
    await watchInvitation();
    final oldResponse = database.callbacks[_relationPath]!.single;
    database.emit(_relationPath, {'status': 'pending'});
    await _tick();
    auth.changeUid('other-contact');
    await _tick();
    expect(invitations.last, isFalse);
    expect(database.streams[_relationPath]!.hasListener, isFalse);
    oldResponse(_Event({'status': 'pending'}));
    await _tick();
    expect(invitations.last, isFalse);
    database.emit('vehicleContacts/vehicle-test/other-contact', {
      'status': 'pending',
    });
    await _tick();
    expect(invitations.last, isTrue);
    auth.changeUid('other-contact');
    await _tick();
    expect(
      database.reads.where((path) => path.endsWith('/other-contact')).length,
      1,
    );
  });

  test('pending invitation queued response cannot survive an identity or status change', () async {
    await watchInvitation();
    var count = invitations.length;
    database.emit(_relationPath, {'status': 'pending'});
    database.emit(_relationPath, {'status': 'revoked'});
    await _tick();
    expect(invitations.skip(count), everyElement(isFalse));
    count = invitations.length;
    database.emit(_relationPath, {'status': 'pending'});
    auth.changeUid('other-contact');
    await _tick();
    expect(invitations.skip(count), everyElement(isFalse));
  });

  test(
    'pending invitation Auth error clears the proposal and releases its read',
    () async {
      await watchInvitation();
      database.emit(_relationPath, {'status': 'pending'});
      await _tick();
      final error = StateError('auth failed');
      auth.changes.addError(error);
      await _tick();
      expect(invitations.last, isFalse);
      expect(invitationErrors, [same(error)]);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
    },
  );

  test(
    'pending invitation cancellation releases Auth and RTDB listeners',
    () async {
      await watchInvitation();
      await invitationSubscription!.cancel();
      expect(auth.changes.hasListener, isFalse);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
    },
  );

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
    expect(auth.changes.hasListener, isFalse);
  });

  test(
    'UID change automatically invalidates and follows only the new user',
    () async {
      await authorize();
      auth.changeUid('other-contact');
      await _tick();
      expect(results.last, isEmpty);
      expect(database.streams[_indexPath]!.hasListener, isFalse);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
      database.emit('users/other-contact/vehicleIds', {'vehicle-test': true});
      await _tick();
      database.emit('vehicleContacts/vehicle-test/other-contact', {
        'status': 'pending',
      });
      await _tick();
      expect(results.last, isEmpty);
      database.emit('vehicleContacts/vehicle-test/other-contact', _active);
      await _tick();
      expect(results.last, {'vehicle-test'});
    },
  );

  test(
    'sign-out automatically clears results and cancels RTDB reads',
    () async {
      await authorize();
      await auth.signOut();
      await _tick();
      expect(results.last, isEmpty);
      expect(database.streams[_indexPath]!.hasListener, isFalse);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
      expect(auth.changes.hasListener, isTrue);
    },
  );

  test(
    'late old index and relation responses cannot affect the new session',
    () async {
      await authorize();
      final oldIndex = database.callbacks[_indexPath]!.single;
      final oldRelation = database.callbacks[_relationPath]!.single;
      auth.changeUid('other-contact');
      await _tick();
      database.emit('users/other-contact/vehicleIds', {'other-vehicle': true});
      await _tick();
      database.emit('vehicleContacts/other-vehicle/other-contact', _active);
      await _tick();
      expect(results.last, {'other-vehicle'});
      final count = results.length;
      oldIndex(_Event({'late-vehicle': true}));
      oldRelation(_Event(_active));
      await _tick();
      expect(results.length, count);
      expect(results.last, {'other-vehicle'});
      expect(
        database.reads,
        isNot(contains('vehicleContacts/late-vehicle/contact-test')),
      );
    },
  );

  test('late responses after logout do not restore authorization', () async {
    await authorize();
    final oldIndex = database.callbacks[_indexPath]!.single;
    final oldRelation = database.callbacks[_relationPath]!.single;
    await auth.signOut();
    await _tick();
    oldIndex(_Event({'vehicle-test': true}));
    oldRelation(_Event(_active));
    await _tick();
    expect(results.last, isEmpty);
    expect(database.streams[_relationPath]!.hasListener, isFalse);
  });

  test(
    'queued authorization is discarded when Auth identity changes',
    () async {
      await discover();
      final count = results.length;
      database.emit(_relationPath, _active); // Result is queued for delivery.
      auth.changeUid('other-contact');
      await _tick();
      expect(results.skip(count), everyElement(isEmpty));
    },
  );

  test(
    'returning to the same UID requires fresh reads after sign-out',
    () async {
      await authorize();
      final oldIndex = database.callbacks[_indexPath]!.single;
      final oldRelation = database.callbacks[_relationPath]!.single;
      await auth.signOut();
      await _tick();
      auth.changeUid('contact-test');
      await _tick();
      oldIndex(_Event({'vehicle-test': true}));
      oldRelation(_Event(_active));
      await _tick();
      expect(results.last, isEmpty);
      database.emit(_indexPath, {'vehicle-test': true});
      await _tick();
      expect(results.last, isEmpty);
      database.emit(_relationPath, _active);
      await _tick();
      expect(results.last, {'vehicle-test'});
    },
  );

  test(
    'Auth read failure invalidates and releases the old session reads',
    () async {
      await authorize();
      final error = StateError('auth failed');
      auth.changes.addError(error);
      await _tick();
      expect(results.last, isEmpty);
      expect(errors, [same(error)]);
      expect(database.streams[_indexPath]!.hasListener, isFalse);
      expect(database.streams[_relationPath]!.hasListener, isFalse);
    },
  );
}
