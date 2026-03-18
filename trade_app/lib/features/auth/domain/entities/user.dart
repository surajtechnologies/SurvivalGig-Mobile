/// User domain entity
class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? location;
  final String? role;
  final bool? isEmailVerified;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.location,
    this.role,
    this.isEmailVerified,
    this.createdAt,
  });

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? location,
    String? role,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
