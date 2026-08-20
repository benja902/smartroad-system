class LocationModel {
  final double latitude;
  final double longitude;
  final String? displayName;
  final DateTime updatedAt;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.displayName,
    required this.updatedAt,
  });

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? displayName,
    DateTime? updatedAt,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      displayName: displayName ?? this.displayName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      displayName: json['displayName'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'displayName': displayName,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
