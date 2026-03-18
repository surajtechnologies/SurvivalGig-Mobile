/// Profile domain entity
class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final bool isVerified;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
    this.isVerified = false,
  });

  Profile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? profileImageUrl,
    bool? isVerified,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
