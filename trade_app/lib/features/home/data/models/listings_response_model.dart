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
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawListings =
        payload['listings'] ??
        payload['items'] ??
        payload['results'] ??
        payload['data'];
    final listings = rawListings is List ? rawListings : const <dynamic>[];

    return ListingsResponseModel(
      success: json['success'] as bool? ?? true,
      listings: listings
          .whereType<Map<String, dynamic>>()
          .map(ListingModel.fromJson)
          .toList(),
      pagination: PaginationModel.fromJson(
        (payload['pagination'] is Map<String, dynamic>
                ? payload['pagination']
                : payload)
            as Map<String, dynamic>,
      ),
    );
  }
}
