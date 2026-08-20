import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class SessionProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _subscription;

  UserModel? _user;
  UserModel? get user => _user;
  bool get isSignedIn => _user != null;

  SessionProvider(this._authRepository) {
    _subscription = _authRepository.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    await _authRepository.signIn(email, password);
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
