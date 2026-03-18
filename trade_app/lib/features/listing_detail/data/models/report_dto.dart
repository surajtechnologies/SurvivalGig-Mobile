/// Create report request model (DTO)
/// Represents API contract for POST /reports
class CreateReportRequestModel {
  final String targetType;
  final String targetId;
  final String reason;
  final String description;

  const CreateReportRequestModel({
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'description': description,
    };
  }
}
