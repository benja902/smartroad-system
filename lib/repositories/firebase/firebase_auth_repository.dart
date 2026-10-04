import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';

import '../../models/user_model.dart';
import '../auth_repository.dart';

/// Firebase-backed AuthRepository. Firebase Auth owns identity
/// (email/password, session); the richer profile (phone, vehicleIds)
/// lives under users/{uid} in Realtime Database and is merged in.
class FirebaseAuthRepository implements AuthRepository {
  final fb_auth.FirebaseAuth _auth;
  final DatabaseReference _usersRef;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? auth,
    FirebaseDatabase? database,
  })  : _auth = auth ?? fb_auth.FirebaseAuth.instance,
        _usersRef = (database ?? FirebaseDatabase.instance).ref('users');

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) => _toUserModel(user));
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Sign-in succeeded but no Firebase user was returned.');
    }

    final user = await _toUserModel(firebaseUser);
    if (user == null) {
      throw const AccountNotProvisionedException();
    }
    return user;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<UserModel?> _toUserModel(fb_auth.User? firebaseUser) async {
    if (firebaseUser == null) return null;

    final snapshot = await _usersRef.child(firebaseUser.uid).get();
    if (!snapshot.exists) {
      if (_auth.currentUser?.uid == firebaseUser.uid) {
        await _auth.signOut();
      }
      return null;
    }
    final profile = Map<String, dynamic>.from(snapshot.value as Map);

    return UserModel(
      id: firebaseUser.uid,
      name: profile['name'] as String? ?? firebaseUser.displayName ?? firebaseUser.email ?? 'Usuario',
      email: profile['email'] as String? ?? firebaseUser.email ?? '',
      phone: profile['phone'] as String? ?? firebaseUser.phoneNumber,
      vehicleIds: (profile['vehicleIds'] as Map?)?.keys.map((k) => k.toString()).toList() ?? const [],
    );
  }
}
