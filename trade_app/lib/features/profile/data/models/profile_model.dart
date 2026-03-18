import '../../../../config/env/app_config.dart';
import '../../domain/entities/profile.dart';

/// Profile DTO model
class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final bool isVerified;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
    this.isVerified = false,
  });

  factory ProfileModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackProfileImageUrl,
  }) {
    final payload = _extractPayload(json);

    return ProfileModel(
      id:
          _readString(payload['id']) ??
          _readString(payload['_id']) ??
          _readString(payload['userId']) ??
          '',
      fullName:
          _readString(payload['name']) ??
          _readString(payload['fullName']) ??
          _readString(payload['full_name']) ??
          _readString(payload['username']) ??
          'User',
      email: _readString(payload['email']) ?? '-',
      profileImageUrl:
          _normalizeImageUrl(
            _readString(payload['profileImage']) ??
                _readString(payload['profile_image']) ??
                _readString(payload['profileImageUrl']) ??
                _readString(payload['avatar']) ??
                _readString(payload['avatarUrl']) ??
                _readString(payload['image']) ??
                _readString(payload['imageUrl']) ??
                _readString(payload['photo']) ??
                _readString(payload['photoUrl']),
          ) ??
          _normalizeImageUrl(fallbackProfileImageUrl),
      isVerified: _readBool(payload['isIdVerified']) ?? false,
    );
  }

  static ProfileModel fromResponse(
    dynamic data, {
    String? fallbackProfileImageUrl,
  }) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile response');
    }

    return ProfileModel.fromJson(
      data,
      fallbackProfileImageUrl: fallbackProfileImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': fullName,
      'email': email,
      'is_verified': isVerified,
      if (profileImageUrl != null) 'profileImage': profileImageUrl,
    };
  }

  Profile toEntity() {
    return Profile(
      id: id,
      fullName: fullName,
      email: email,
      profileImageUrl: profileImageUrl,
      isVerified: isVerified,
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final data = json['data'];

    if (data is Map<String, dynamic>) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        return user;
      }

      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        return profile;
      }

      return data;
    }

    final user = json['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }

    final profile = json['profile'];
    if (profile is Map<String, dynamic>) {
      return profile;
    }

    return json;
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
    }

    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
      if (lower == '1') return true;
      if (lower == '0') return false;
    }

    return null;
  }

  static String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final baseUrl = AppConfig.baseUrl;
    if (url.startsWith('/api/')) {
      final trimmedBase = baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : baseUrl;
      return '$trimmedBase$url';
    }

    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }

    return '$baseUrl/$url';
  }
}
