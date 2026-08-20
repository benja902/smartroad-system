import 'package:firebase_database/firebase_database.dart';

import '../../models/vehicle_model.dart';
import '../vehicle_repository.dart';

/// Firebase-backed VehicleRepository. Queries vehicles/ by ownerId
/// (indexed — see database.rules.json) and takes the first match as the
/// user's primary vehicle. Multi-vehicle fleets are a later feature.
class FirebaseVehicleRepository implements VehicleRepository {
  final DatabaseReference _vehiclesRef;

  FirebaseVehicleRepository({FirebaseDatabase? database})
      : _vehiclesRef = (database ?? FirebaseDatabase.instance).ref('vehicles');

  @override
  Stream<VehicleModel?> watchPrimaryVehicle(String userId) {
    return _vehiclesRef.orderByChild('ownerId').equalTo(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      final entry = raw.entries.first;
      final data = Map<String, dynamic>.from(entry.value as Map);

      return VehicleModel(
        id: entry.key,
        ownerId: data['ownerId'] as String,
        deviceId: data['deviceId'] as String,
        brand: data['brand'] as String,
        model: data['model'] as String,
        plate: data['plate'] as String,
      );
    });
  }
}
