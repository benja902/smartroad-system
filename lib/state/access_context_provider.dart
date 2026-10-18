import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

enum AccessStatus { signedOut, loading, owner, restricted, error }

/// Entry context for the current relationship, not a global user role.
class AccessContextProvider extends ChangeNotifier {
  final Stream<OwnerVehicleResolution> Function(String) _watchOwner;
  StreamSubscription<OwnerVehicleResolution>? _subscription;
  String? _userId;
  String? get userId => _userId;
  var _version = 0;
  var _disposed = false;
  AccessStatus _status = AccessStatus.signedOut;
  AccessStatus get status => _status;
  VehicleModel? _vehicle;
  VehicleModel? get vehicle => _vehicle;
  Object? _error;
  Object? get error => _error;
  Object? _sessionError;

  AccessContextProvider(this._watchOwner);

  void setSession(String? userId, {Object? error}) {
    if (_userId == userId && identical(_sessionError, error)) return;
    _userId = userId;
    _sessionError = error;
    _subscription?.cancel();
    final version = ++_version;
    _vehicle = null;
    _error = error;
    _status = error != null
        ? AccessStatus.error
        : userId == null
        ? AccessStatus.signedOut
        : AccessStatus.loading;
    if (userId != null && error == null) {
      _subscription = _watchOwner(userId).listen(
        (result) {
          if (_disposed || version != _version) return;
          _error = null;
          _vehicle = result.loading ? null : result.vehicle;
          // A supplied repository cannot turn another user's vehicle into ownership.
          if (_vehicle?.ownerId != userId) _vehicle = null;
          _status = result.loading
              ? AccessStatus.loading
              : _vehicle != null
              ? AccessStatus.owner
              : AccessStatus.restricted;
          notifyListeners();
        },
        onError: (Object error) {
          if (_disposed || version != _version) return;
          _vehicle = null;
          _error = error;
          _status = AccessStatus.error;
          notifyListeners();
        },
        onDone: () {
          if (_disposed || version != _version) return;
          _vehicle = null;
          _error ??= StateError('Owner relationship stream ended');
          _status = AccessStatus.error;
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  void retry() {
    final uid = _userId;
    if (uid == null) return;
    _userId = null;
    setSession(uid);
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    _subscription?.cancel();
    super.dispose();
  }
}
