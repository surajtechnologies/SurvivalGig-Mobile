import 'category_model.dart';

/// Response model for categories API endpoint
class CategoriesResponseModel {
  final bool success;
  final List<CategoryModel> categories;

  const CategoriesResponseModel({
    required this.success,
    required this.categories,
  });

  /// Convert from JSON (API response)
  factory CategoriesResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct array and data-wrapped format
    List<dynamic>? categoriesJson;
    
    if (json['categories'] != null) {
      categoriesJson = json['categories'] as List<dynamic>;
    } else if (json['data'] != null && json['data']['categories'] != null) {
      categoriesJson = json['data']['categories'] as List<dynamic>;
    }
    
    return CategoriesResponseModel(
      success: json['success'] ?? json['status'] == 'success',
      categories: categoriesJson
              ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
