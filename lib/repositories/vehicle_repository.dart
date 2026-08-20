import '../models/vehicle_model.dart';

abstract class VehicleRepository {
  /// The signed-in user's primary vehicle, or null if none is configured
  /// yet. Stream-based for the same reason DeviceRepository/EventRepository
  /// are: a future provisioning flow can push vehicle changes live.
  Stream<VehicleModel?> watchPrimaryVehicle(String userId);
}
