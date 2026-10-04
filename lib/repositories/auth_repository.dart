import '../models/user_model.dart';

class AccountNotProvisionedException implements Exception {
  const AccountNotProvisionedException();
}

abstract class AuthRepository {
  /// Emits the current user on subscribe, then again on every sign-in/out.
  Stream<UserModel?> authStateChanges();

  Future<UserModel> signIn(String email, String password);

  Future<void> signOut();
}
