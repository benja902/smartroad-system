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
  Object? _error;
  Object? get error => _error;

  SessionProvider(this._authRepository) {
    _subscription = _authRepository.authStateChanges().listen(
      (user) {
        _user = user;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _user = null;
        _error = error;
        notifyListeners();
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    await _authRepository.signIn(email, password);
  }

  Future<void> signOut() async {
    _user = null;
    _error = null;
    notifyListeners();
    try {
      await _authRepository.signOut();
    } catch (error) {
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
