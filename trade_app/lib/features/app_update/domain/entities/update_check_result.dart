/// Type of update available
enum UpdateType {
  /// No update needed
  none,

  /// Optional update available
  optional,

  /// Forced update required
  forced,
}

/// Domain entity representing the result of an update check
class UpdateCheckResult {
  final UpdateType type;
  final String currentVersion;
  final String latestVersion;
  final String updateMessage;
  final String storeUrl;
  final bool isSnoozed;

  const UpdateCheckResult({
    required this.type,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateMessage,
    required this.storeUrl,
    required this.isSnoozed,
  });

  UpdateCheckResult copyWith({
    UpdateType? type,
    String? currentVersion,
    String? latestVersion,
    String? updateMessage,
    String? storeUrl,
    bool? isSnoozed,
  }) {
    return UpdateCheckResult(
      type: type ?? this.type,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      updateMessage: updateMessage ?? this.updateMessage,
      storeUrl: storeUrl ?? this.storeUrl,
      isSnoozed: isSnoozed ?? this.isSnoozed,
    );
  }
}
