class VehicleModel {
  final String id;
  final String ownerId;
  final String deviceId;
  final String brand;
  final String model;
  final String plate;

  const VehicleModel({
    required this.id,
    required this.ownerId,
    required this.deviceId,
    required this.brand,
    required this.model,
    required this.plate,
  });

  VehicleModel copyWith({
    String? id,
    String? ownerId,
    String? deviceId,
    String? brand,
    String? model,
    String? plate,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plate: plate ?? this.plate,
    );
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      deviceId: json['deviceId'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      plate: json['plate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'deviceId': deviceId,
      'brand': brand,
      'model': model,
      'plate': plate,
    };
  }
}
