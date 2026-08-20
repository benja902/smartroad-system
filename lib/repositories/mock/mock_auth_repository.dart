import 'dart:async';

import '../../models/user_model.dart';
import '../auth_repository.dart';
import 'mock_data_seed.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _current = MockDataSeed.user;

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    _current = MockDataSeed.user.copyWith(email: email);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}
