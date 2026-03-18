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
    // Handle different response formats
    final data = json['data'] ?? json;

    List<String> urls = [];
    if (data['urls'] != null) {
      urls = List<String>.from(data['urls']);
    } else if (data['url'] != null) {
      // Single URL response
      urls = [data['url'] as String];
    } else if (json['urls'] != null) {
      urls = List<String>.from(json['urls']);
    } else if (json['url'] != null) {
      urls = [json['url'] as String];
    }

    return UploadImagesResponseModel(
      success:
          json['success'] ?? json['status'] == 'success' ?? urls.isNotEmpty,
      urls: urls,
      message: json['message'] as String?,
    );
  }
}
