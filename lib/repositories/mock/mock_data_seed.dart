import '../../models/device_status.dart';
import '../../models/location_model.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';

/// Canned starting data shared by every mock repository so Home, Alertas,
/// and the /dev panel all start from one consistent fixture.
class MockDataSeed {
  MockDataSeed._();

  static const String userId = 'user-1';
  static const String vehicleId = 'vehicle-1';
  static const String deviceId = 'device-1';

  static final UserModel user = UserModel(
    id: userId,
    name: 'Mariana Quispe',
    email: 'mariana.quispe@example.com',
    phone: '+51 987 654 321',
    vehicleIds: const [vehicleId],
  );

  static final VehicleModel vehicle = VehicleModel(
    id: vehicleId,
    ownerId: userId,
    deviceId: deviceId,
    brand: 'Toyota',
    model: 'Hilux',
    plate: 'ABC-123',
  );

  static LocationModel get initialLocation => LocationModel(
        latitude: -12.046374,
        longitude: -77.042793,
        displayName: 'Av. Javier Prado Este, San Isidro, Lima',
        updatedAt: DateTime.now(),
      );

  static DeviceStatus get initialDeviceStatus => DeviceStatus(
        deviceId: deviceId,
        online: true,
        monitoring: true,
        adxl375Connected: true,
        lsm6ds3Connected: true,
        sim7000Connected: true,
        cellularConnected: true,
        networkType: NetworkType.cellular4g,
        signalStrength: 4,
        gnssAvailable: true,
        gnssFix: true,
        lastSeen: DateTime.now(),
        location: initialLocation,
      );
}
