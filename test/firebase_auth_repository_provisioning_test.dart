import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/models/user_model.dart';
import 'package:smartroad/repositories/auth_repository.dart';
import 'package:smartroad/repositories/firebase/firebase_auth_repository.dart';
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/state/session_provider.dart';

class _User extends Fake implements fb_auth.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName = null;
  @override
  final String? phoneNumber = null;

  _User(this.uid, {this.email});
}

class _Credential extends Fake implements fb_auth.UserCredential {
  @override
  final fb_auth.User? user;

  _Credential(this.user);
}

class _Auth extends Fake implements fb_auth.FirebaseAuth {
  final fb_auth.User user;
  final bool restored;
  final _changes = StreamController<fb_auth.User?>.broadcast();
  fb_auth.User? _current;
  int signOutCount = 0;

  _Auth(this.user, {this.restored = false}) : _current = restored ? user : null;

  @override
  fb_auth.User? get currentUser => _current;

  @override
  Stream<fb_auth.User?> authStateChanges() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<fb_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _current = user;
    _changes.add(user);
    return _Credential(user);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    _current = null;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

class _Snapshot extends Fake implements DataSnapshot {
  @override
  final bool exists;
  @override
  final Object? value;

  _Snapshot(this.exists, this.value);
}

class _Reference extends Fake implements DatabaseReference {
  final _Database database;
  final String? uid;

  _Reference(this.database, [this.uid]);

  @override
  DatabaseReference child(String path) => _Reference(database, path);

  @override
  Future<DataSnapshot> get() async {
    database.readCount++;
    if (database.readError != null) throw database.readError!;
    return _Snapshot(database.profiles.containsKey(uid), database.profiles[uid]);
  }
}

class _Database extends Fake implements FirebaseDatabase {
  final Map<String, Object?> profiles;
  Object? readError;
  int readCount = 0;

  _Database(this.profiles, {this.readError});

  @override
  DatabaseReference ref([String? path]) {
    expect(path, 'users');
    return _Reference(this);
  }
}

class _UnprovisionedAuthRepository implements AuthRepository {
  @override
  Stream<UserModel?> authStateChanges() => Stream.value(null);

  @override
  Future<UserModel> signIn(String email, String password) async =>
      throw const AccountNotProvisionedException();

  @override
  Future<void> signOut() async {}
}

void main() {
  final identity = _User('owner', email: 'owner@example.test');

  test('provisioned owner keeps their existing vehicle', () async {
    final auth = _Auth(identity);
    final database = _Database({
      'owner': {
        'name': 'Propietario',
        'email': 'owner@example.test',
        'vehicleIds': {'vehicle-1': true},
      },
    });
    final repository = FirebaseAuthRepository(auth: auth, database: database);

    final user = await repository.signIn('owner@example.test', 'password');

    expect(user.id, 'owner');
    expect(user.vehicleIds, ['vehicle-1']);
    expect(auth.signOutCount, 0);
    expect(database.readCount, 1);
    await auth.dispose();
  });

  test('existing contact profile without a vehicle is accepted', () async {
    final auth = _Auth(_User('contact', email: 'contact@example.test'));
    final database = _Database({
      'contact': {'name': 'Contacto', 'email': 'contact@example.test'},
    });
    final repository = FirebaseAuthRepository(auth: auth, database: database);

    final user = await repository.signIn('contact@example.test', 'password');

    expect(user.vehicleIds, isEmpty);
    expect(auth.signOutCount, 0);
    await auth.dispose();
  });

  test('explicit sign-in without RTDB profile signs out and reports provisioning', () async {
    final auth = _Auth(identity);
    final database = _Database({});
    final repository = FirebaseAuthRepository(auth: auth, database: database);

    await expectLater(
      repository.signIn('owner@example.test', 'password'),
      throwsA(isA<AccountNotProvisionedException>()),
    );
    expect(auth.currentUser, isNull);
    expect(auth.signOutCount, 1);
    await auth.dispose();
  });

  test('restored Auth session without RTDB profile returns to signed-out state', () async {
    final auth = _Auth(identity, restored: true);
    final repository = FirebaseAuthRepository(auth: auth, database: _Database({}));

    expect(await repository.authStateChanges().first, isNull);
    expect(auth.currentUser, isNull);
    expect(auth.signOutCount, 1);
    await auth.dispose();
  });

  test('RTDB read error is not mistaken for an absent profile', () async {
    final auth = _Auth(identity);
    final database = _Database({}, readError: StateError('read unavailable'));
    final repository = FirebaseAuthRepository(auth: auth, database: database);

    await expectLater(
      repository.signIn('owner@example.test', 'password'),
      throwsA(isA<StateError>()),
    );
    expect(auth.currentUser?.uid, 'owner');
    expect(auth.signOutCount, 0);
    await auth.dispose();
  });

  testWidgets('login shows a specific message for an unprovisioned account', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => SessionProvider(_UnprovisionedAuthRepository()),
          child: const LoginScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'owner@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Esta cuenta aún no está provisionada.'), findsOneWidget);
  });
}
