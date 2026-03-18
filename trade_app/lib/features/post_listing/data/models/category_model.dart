import '../../../../shared/models/category.dart';

/// Category model (DTO) - represents API contract ONLY
/// Maps to/from JSON for API communication
class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? parentId;
  final int? sortOrder;
  final bool isActive;
  final List<CategoryModel>? children;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.parentId,
    this.sortOrder,
    required this.isActive,
    this.children,
  });

  /// Convert from JSON (API response)
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      parentId: json['parentId'] ?? json['parent_id'] as String?,
      sortOrder: json['sortOrder'] ?? json['sort_order'] as int?,
      isActive: json['isActive'] ?? json['is_active'] as bool? ?? true,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      if (parentId != null) 'parentId': parentId,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'isActive': isActive,
      if (children != null)
        'children': children!.map((e) => e.toJson()).toList(),
    };
  }

  /// Convert model to shared entity
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      icon: icon,
      parentId: parentId,
      sortOrder: sortOrder,
      isActive: isActive,
      children: children?.map((e) => e.toEntity()).toList(),
    );
  }
}
