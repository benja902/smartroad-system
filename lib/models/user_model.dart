class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> vehicleIds;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.vehicleIds = const [],
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? vehicleIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleIds: vehicleIds ?? this.vehicleIds,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      vehicleIds: (json['vehicleIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleIds': vehicleIds,
    };
  }
}
