import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../models/vehicle_model.dart';
import '../vehicle_repository.dart';

/// Resolves the single owner vehicle using the administrative relationship
/// and the existing ownerId query. Neither an index alone nor a query's
/// first result is enough to select a vehicle.
class FirebaseVehicleRepository implements VehicleRepository {
  final DatabaseReference _vehiclesRef;
  final DatabaseReference _usersRef;

  FirebaseVehicleRepository({FirebaseDatabase? database})
      : _vehiclesRef = (database ?? FirebaseDatabase.instance).ref('vehicles'),
        _usersRef = (database ?? FirebaseDatabase.instance).ref('users');

  @override
  Stream<VehicleModel?> watchPrimaryVehicle(String userId) {
    if (userId.trim().isEmpty) return Stream.value(null);
    late StreamController<VehicleModel?> controller;
    StreamSubscription<DatabaseEvent>? ownerSubscription;
    StreamSubscription<DatabaseEvent>? vehiclesSubscription;
    String? ownerVehicleId;

    controller = StreamController<VehicleModel?>(
      onListen: () {
        ownerSubscription = _usersRef.child(userId).child('ownerVehicleId').onValue.listen(
          (event) {
            final value = event.snapshot.value;
            final nextId = value is String && value.isNotEmpty ? value : null;
            if (nextId == ownerVehicleId && vehiclesSubscription != null) return;
            ownerVehicleId = nextId;
            vehiclesSubscription?.cancel();
            vehiclesSubscription = null;
            controller.add(null);
            if (nextId == null) return;

            vehiclesSubscription = _vehiclesRef
                .orderByChild('ownerId')
                .equalTo(userId)
                .onValue
                .listen(
                  (vehicleEvent) {
                    if (ownerVehicleId != nextId) return;
                    final value = vehicleEvent.snapshot.value;
                    if (value is! Map || value.length != 1 || !value.containsKey(nextId)) {
                      controller.add(null);
                      return;
                    }
                    final data = value[nextId];
                    if (data is! Map ||
                        data['ownerId'] != userId ||
                        data['deviceId'] is! String ||
                        (data['deviceId'] as String).isEmpty ||
                        data['brand'] is! String ||
                        data['model'] is! String ||
                        data['plate'] is! String) {
                      controller.add(null);
                      return;
                    }
                    controller.add(VehicleModel(
                      id: nextId,
                      ownerId: userId,
                      deviceId: data['deviceId'] as String,
                      brand: data['brand'] as String,
                      model: data['model'] as String,
                      plate: data['plate'] as String,
                    ));
                  },
                  onError: (Object error, StackTrace stackTrace) {
                    if (ownerVehicleId != nextId) return;
                    controller.add(null);
                    controller.addError(error, stackTrace);
                  },
                );
          },
          onError: (Object error, StackTrace stackTrace) {
            ownerVehicleId = null;
            vehiclesSubscription?.cancel();
            vehiclesSubscription = null;
            controller.add(null);
            controller.addError(error, stackTrace);
          },
        );
      },
      onCancel: () async {
        await ownerSubscription?.cancel();
        await vehiclesSubscription?.cancel();
      },
    );
    return controller.stream;
  }
}
