import '../../domain/entities/user.dart' as domain;

/// User model (DTO) - represents API contract ONLY
/// Maps to/from JSON for API communication
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? location;
  final String? role;
  final int? pointsAvailable;
  final bool? isEmailVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.location,
    this.role,
    this.pointsAvailable,
    this.isEmailVerified,
    this.createdAt,
  });

  /// Convert from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase and snake_case for createdAt (optional for login)
    final createdAtValue = json['createdAt'] ?? json['created_at'];

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      role: json['role'] as String?,
      pointsAvailable: json['pointsAvailable'] as int?,
      isEmailVerified: json['isEmailVerified'] as bool?,
      createdAt: createdAtValue != null ? DateTime.parse(createdAtValue as String) : null,
    );
  }

  /// Convert to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (role != null) 'role': role,
      if (pointsAvailable != null) 'pointsAvailable': pointsAvailable,
      if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Convert model to domain entity
  domain.User toEntity() {
    return domain.User(
      id: id,
      email: email,
      name: name,
      phone: phone,
      location: location,
      role: role,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
    );
  }
}
