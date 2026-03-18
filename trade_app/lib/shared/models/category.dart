/// Category shared model
/// Used across multiple features (home, post_listing, etc.)
class Category {
  final String id;
  final String name;
  final String? icon;
  final String? parentId;
  final int? sortOrder;
  final bool isActive;
  final List<Category>? children;

  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.parentId,
    this.sortOrder,
    required this.isActive,
    this.children,
  });

  /// Create a copy with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? parentId,
    int? sortOrder,
    bool? isActive,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      children: children ?? this.children,
    );
  }
}
