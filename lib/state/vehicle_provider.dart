import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

/// Reactive to the signed-in user: call [setUserId] whenever
/// SessionProvider's user changes (see AppProviders) rather than passing a
/// fixed userId at construction, since the real user is only known after
/// Firebase Auth resolves.
class VehicleProvider extends ChangeNotifier {
  final VehicleRepository _vehicleRepository;
  StreamSubscription<VehicleModel?>? _subscription;
  String? _userId;

  VehicleModel? _vehicle;
  VehicleModel? get vehicle => _vehicle;

  VehicleProvider(this._vehicleRepository);

  /// Production entry already observes and validates the owner relationship.
  void setResolvedVehicle(VehicleModel? vehicle) {
    if (identical(_vehicle, vehicle)) return;
    _subscription?.cancel();
    _userId = null;
    _vehicle = vehicle;
    notifyListeners();
  }

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;

    _subscription?.cancel();
    _vehicle = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    _subscription = _vehicleRepository
        .watchPrimaryVehicle(userId)
        .listen(
          (vehicle) {
            _vehicle = vehicle;
            notifyListeners();
          },
          onError: (Object _) {
            _vehicle = null;
            notifyListeners();
          },
        );
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
