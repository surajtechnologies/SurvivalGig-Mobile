/// Device token request DTO
/// Represents API contract for registering FCM token
class DeviceTokenRequestModel {
  final String token;
  final String platform;

  const DeviceTokenRequestModel({required this.token, required this.platform});

  Map<String, dynamic> toJson() {
    return {'token': token, 'platform': platform};
  }
}

/// Device token response DTO
/// Represents API response for device token registration
class DeviceTokenResponseModel {
  final bool success;
  final String message;
  final DeviceTokenDataModel? deviceToken;

  const DeviceTokenResponseModel({
    required this.success,
    required this.message,
    this.deviceToken,
  });

  factory DeviceTokenResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final deviceTokenJson =
        json['deviceToken'] ??
        (data is Map<String, dynamic> ? data['deviceToken'] ?? data : null);
    final deviceToken = deviceTokenJson is Map<String, dynamic>
        ? DeviceTokenDataModel.fromJson(deviceTokenJson)
        : null;

    return DeviceTokenResponseModel(
      success: json['success'] as bool? ?? deviceToken != null,
      message: json['message'] as String? ?? '',
      deviceToken: deviceToken,
    );
  }
}

/// Device token data model from API response
class DeviceTokenDataModel {
  final String id;
  final String token;
  final String platform;
  final String createdAt;

  const DeviceTokenDataModel({
    required this.id,
    required this.token,
    required this.platform,
    required this.createdAt,
  });

  factory DeviceTokenDataModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenDataModel(
      id: json['id'] as String? ?? '',
      token: json['token'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
