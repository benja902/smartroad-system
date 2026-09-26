import '../../models/device_diagnostics.dart';
import '../../models/device_operational_state.dart';
import '../../models/device_status.dart';
import '../../models/gnss_position.dart';
import '../../models/modem_status.dart';
import '../../models/power_status.dart';
import '../../models/sensor_diagnostics.dart';
import '../../models/storage_status.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';

/// Canned starting data shared by every mock repository so Home, Alertas,
/// and the /dev panel all start from one consistent fixture, shaped like
/// the real firmware payloads (docs/device_contract.md).
class MockDataSeed {
  MockDataSeed._();

  static const String userId = 'user-1';
  static const String vehicleId = 'vehicle-1';
  static const String deviceId = 'SDA-A4C138';

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

  static GnssPosition get initialPosition => const GnssPosition(
        fix: true,
        latitude: -12.046374,
        longitude: -77.042793,
        altitudeM: 154,
        speedKmh: 0,
        heading: 218,
        hdop: 1.1,
        satellites: 9,
        fixAgeS: 2,
      );

  static DeviceStatus get initialDeviceStatus => DeviceStatus(
        deviceId: deviceId,
        state: DeviceOperationalState.idle,
        firmwareVersion: '1.0.0',
        adxl375: const AdxlSensorStatus(ok: true, address: '0x53', peakG60s: 1.4),
        lsm6ds3: const ImuSensorStatus(ok: true, address: '0x6A', tiltDeg: 3.1, gyroMaxDps: 12.0),
        pcf8574: const ExpanderStatus(ok: true, address: '0x20'),
        inputs: const ButtonInputs(sos: false, cancel: false),
        outputs: const OutputSignals(ledRed: false, ledGreen: true, buzzer: false),
        storage: const StorageStatus(present: true, totalMb: 15200, freeMb: 14980, queuedEvents: 0),
        modem: const ModemStatus(registered: true, tech: 'LTE', operatorName: 'Claro PE', rssiDbm: -73),
        gnss: initialPosition,
        power: const PowerStatus(batteryV: 4.02, charging: true, vinOk: true),
        system: const SystemDiagnostics(uptimeS: 48213, heapFree: 148320, resetReason: 'POWERON'),
        online: true,
        lastSeen: DateTime.now(),
      );
}
