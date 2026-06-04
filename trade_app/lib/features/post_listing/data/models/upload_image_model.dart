import '../../../../core/utils/upload_response_parser.dart';

/// Upload images response model (DTO)
class UploadImagesResponseModel {
  final bool success;
  final List<String> urls;
  final String? message;

  const UploadImagesResponseModel({
    required this.success,
    required this.urls,
    this.message,
  });

  /// Convert from JSON (API response)
  factory UploadImagesResponseModel.fromJson(Map<String, dynamic> json) {
    final urls = extractUploadedImageUrls(json);
    final success = json['success'] == true || json['status'] == 'success';

    return UploadImagesResponseModel(
      success: success || urls.isNotEmpty,
      urls: urls,
      message: json['message'] as String?,
    );
  }
}
