import 'location_model.dart';

enum NetworkType { none, cellular2g, cellular3g, cellular4g, wifi }

extension NetworkTypeLabel on NetworkType {
  String get label {
    switch (this) {
      case NetworkType.none:
        return 'Sin conexión celular';
      case NetworkType.cellular2g:
        return '2G conectado';
      case NetworkType.cellular3g:
        return '3G conectado';
      case NetworkType.cellular4g:
        return '4G conectado';
      case NetworkType.wifi:
        return 'Wi-Fi conectado';
    }
  }
}

class DeviceStatus {
  final String deviceId;
  final bool online;
  final bool monitoring;
  final bool adxl375Connected;
  final bool lsm6ds3Connected;
  final bool sim7000Connected;
  final bool cellularConnected;
  final NetworkType networkType;

  /// Signal bars, 0-4.
  final int signalStrength;
  final bool gnssAvailable;
  final bool gnssFix;
  final DateTime lastSeen;
  final LocationModel? location;

  const DeviceStatus({
    required this.deviceId,
    required this.online,
    required this.monitoring,
    required this.adxl375Connected,
    required this.lsm6ds3Connected,
    required this.sim7000Connected,
    required this.cellularConnected,
    required this.networkType,
    required this.signalStrength,
    required this.gnssAvailable,
    required this.gnssFix,
    required this.lastSeen,
    this.location,
  });

  DeviceStatus copyWith({
    String? deviceId,
    bool? online,
    bool? monitoring,
    bool? adxl375Connected,
    bool? lsm6ds3Connected,
    bool? sim7000Connected,
    bool? cellularConnected,
    NetworkType? networkType,
    int? signalStrength,
    bool? gnssAvailable,
    bool? gnssFix,
    DateTime? lastSeen,
    LocationModel? location,
  }) {
    return DeviceStatus(
      deviceId: deviceId ?? this.deviceId,
      online: online ?? this.online,
      monitoring: monitoring ?? this.monitoring,
      adxl375Connected: adxl375Connected ?? this.adxl375Connected,
      lsm6ds3Connected: lsm6ds3Connected ?? this.lsm6ds3Connected,
      sim7000Connected: sim7000Connected ?? this.sim7000Connected,
      cellularConnected: cellularConnected ?? this.cellularConnected,
      networkType: networkType ?? this.networkType,
      signalStrength: signalStrength ?? this.signalStrength,
      gnssAvailable: gnssAvailable ?? this.gnssAvailable,
      gnssFix: gnssFix ?? this.gnssFix,
      lastSeen: lastSeen ?? this.lastSeen,
      location: location ?? this.location,
    );
  }

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      deviceId: json['deviceId'] as String,
      online: json['online'] as bool,
      monitoring: json['monitoring'] as bool,
      adxl375Connected: json['adxl375Connected'] as bool,
      lsm6ds3Connected: json['lsm6ds3Connected'] as bool,
      sim7000Connected: json['sim7000Connected'] as bool,
      cellularConnected: json['cellularConnected'] as bool,
      networkType: NetworkType.values.byName(json['networkType'] as String),
      signalStrength: json['signalStrength'] as int,
      gnssAvailable: json['gnssAvailable'] as bool,
      gnssFix: json['gnssFix'] as bool,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'online': online,
      'monitoring': monitoring,
      'adxl375Connected': adxl375Connected,
      'lsm6ds3Connected': lsm6ds3Connected,
      'sim7000Connected': sim7000Connected,
      'cellularConnected': cellularConnected,
      'networkType': networkType.name,
      'signalStrength': signalStrength,
      'gnssAvailable': gnssAvailable,
      'gnssFix': gnssFix,
      'lastSeen': lastSeen.toIso8601String(),
      'location': location?.toJson(),
    };
  }
}
