import '../../domain/entities/update_check_result.dart';

/// DTO model for update check result
class UpdateCheckResultModel {
  final UpdateType type;
  final String currentVersion;
  final String latestVersion;
  final String updateMessage;
  final String storeUrl;
  final bool isSnoozed;

  const UpdateCheckResultModel({
    required this.type,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateMessage,
    required this.storeUrl,
    required this.isSnoozed,
  });

  UpdateCheckResult toEntity() {
    return UpdateCheckResult(
      type: type,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      updateMessage: updateMessage,
      storeUrl: storeUrl,
      isSnoozed: isSnoozed,
    );
  }
}
