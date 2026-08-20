import '../../models/vehicle_model.dart';
import '../vehicle_repository.dart';
import 'mock_data_seed.dart';

class MockVehicleRepository implements VehicleRepository {
  @override
  Stream<VehicleModel?> watchPrimaryVehicle(String userId) async* {
    yield MockDataSeed.vehicle;
  }
}
