import 'listing_model.dart';
import 'pagination_model.dart';

/// Response model for listings API endpoint
class ListingsResponseModel {
  final bool success;
  final List<ListingModel> listings;
  final PaginationModel pagination;

  const ListingsResponseModel({
    required this.success,
    required this.listings,
    required this.pagination,
  });

  /// Convert from JSON (API response)
  factory ListingsResponseModel.fromJson(Map<String, dynamic> json) {
    return ListingsResponseModel(
      success: json['success'] as bool? ?? true,
      listings: (json['listings'] as List<dynamic>)
          .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}
