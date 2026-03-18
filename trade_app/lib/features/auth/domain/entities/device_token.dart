/// Device token domain entity
/// Pure Dart only - no Flutter, Dio, Firebase, or JSON imports
class DeviceToken {
  final String id;
  final String token;
  final String platform;
  final DateTime? createdAt;

  const DeviceToken({
    required this.id,
    required this.token,
    required this.platform,
    this.createdAt,
  });
}
