import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../home/data/models/listing_model.dart';
import '../../../home/data/models/pagination_model.dart';
import '../models/listing_trade_offer_model.dart';
import '../models/report_dto.dart';
import '../models/user_review_summary_model.dart';

/// Listing detail remote datasource
/// Responsible for making API calls only
abstract class ListingDetailRemoteDataSource {
  /// Get listing details by ID
  Future<ListingModel> getListingById({required String id});

  /// Fetch current user's listings with pagination.
  Future<({List<ListingModel> listings, PaginationModel pagination})>
  getMyListings({required int page, required int limit});

  /// Get ratings and reviews summary for a user.
  Future<UserReviewSummaryModel> getUserReviews({
    required String userId,
    required int page,
    required int limit,
  });

  /// Buy now (direct purchase) for a listing
  Future<void> buyNow({required String listingId});

  /// Delete listing by ID.
  Future<void> deleteListing({required String listingId});

  /// Submit report for a listing/user/trade
  Future<String> submitReport({required CreateReportRequestModel request});

  /// Check pending trades for a listing.
  Future<List<ListingTradeOfferModel>> getListingPendingTrades({
    required String listingId,
  });
}

class ListingDetailRemoteDataSourceImpl
    implements ListingDetailRemoteDataSource {
  final DioClient dioClient;

  ListingDetailRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ListingModel> getListingById({required String id}) async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.getListingById(id));

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Handle response format: { status: 'success', data: { listing: {...} } }
          final responseData = data['data'] ?? data;
          final listingJson = responseData['listing'] ?? responseData;

          if (listingJson != null && listingJson is Map<String, dynamic>) {
            return ListingModel.fromJson(listingJson);
          }

          throw ServerException(
            message: 'Invalid listing data format',
            code: 'INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }

        throw ServerException(
          message: 'Invalid response format',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to get listing',
          code: response.data['code'] ?? 'GET_LISTING_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<({List<ListingModel> listings, PaginationModel pagination})>
  getMyListings({required int page, required int limit}) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.myListings,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw ServerException(
            message: 'Invalid response format',
            code: 'INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }

        final payload = _extractResponsePayload(data);
        final rawListings = _extractListingsArray(payload);
        if (rawListings == null) {
          throw ServerException(
            message: 'Invalid listings data format',
            code: 'INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }

        final listings = <ListingModel>[];
        for (final rawListing in rawListings) {
          if (rawListing is Map<String, dynamic>) {
            try {
              listings.add(ListingModel.fromJson(rawListing));
            } catch (_) {
              // Skip malformed listing rows instead of failing the full response.
            }
          }
        }

        final pagination = _parsePagination(
          payload: payload,
          page: page,
          limit: limit,
          listingsCount: listings.length,
        );

        return (listings: listings, pagination: pagination);
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to load listings',
        code: 'MY_LISTINGS_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(
        message: 'Failed to parse listings response',
        code: 'INVALID_RESPONSE',
      );
    }
  }

  @override
  Future<UserReviewSummaryModel> getUserReviews({
    required String userId,
    required int page,
    required int limit,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.getUserReviews(userId),
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return UserReviewSummaryModel.fromApiResponse(response.data);
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to load reviews',
        code: 'GET_USER_REVIEWS_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(
        message: 'Failed to parse user reviews response',
        code: 'INVALID_RESPONSE',
      );
    }
  }

  @override
  Future<void> buyNow({required String listingId}) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.buyNow(listingId),
        data: {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to accept offer',
        code: 'BUY_NOW_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteListing({required String listingId}) async {
    try {
      final response = await dioClient.dio.delete(
        ApiEndpoints.deleteListing(listingId),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        return;
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to delete listing',
        code: 'DELETE_LISTING_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> submitReport({
    required CreateReportRequestModel request,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.reports,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(
              message: data['message'] ?? 'Failed to submit report',
              code: data['code'] ?? 'REPORT_SUBMIT_FAILED',
              statusCode: response.statusCode,
            );
          }

          final message = data['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }

        return 'Report submitted successfully';
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to submit report',
        code: 'REPORT_SUBMIT_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<ListingTradeOfferModel>> getListingPendingTrades({
    required String listingId,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.listingTrades(listingId),
        queryParameters: {'status': 'PENDING'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw ServerException(
            message: 'Invalid response format',
            code: 'INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }

        final tradesRaw =
            data['trades'] ??
            (data['data'] is Map<String, dynamic>
                ? (data['data'] as Map<String, dynamic>)['trades']
                : null);

        if (tradesRaw is! List) {
          return const [];
        }

        final trades = <ListingTradeOfferModel>[];
        for (final row in tradesRaw) {
          if (row is Map<String, dynamic>) {
            trades.add(ListingTradeOfferModel.fromJson(row));
          }
        }
        return trades;
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to load trades',
        code: 'GET_LISTING_TRADES_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (data['message'] != null) {
      return data['message'] as String;
    }

    if (data['error'] != null) {
      if (data['error'] is String) {
        return data['error'] as String;
      }
      if (data['error'] is List && (data['error'] as List).isNotEmpty) {
        final firstError = (data['error'] as List).first;
        if (firstError is Map && firstError['message'] != null) {
          return firstError['message'] as String;
        }
      }
    }

    return null;
  }

  Map<String, dynamic> _extractResponsePayload(Map<String, dynamic> data) {
    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return data;
  }

  List<dynamic>? _extractListingsArray(Map<String, dynamic> payload) {
    final direct =
        payload['listings'] ??
        payload['items'] ??
        payload['results'] ??
        payload['rows'];
    if (direct is List) {
      return direct;
    }

    final nestedData = payload['data'];
    if (nestedData is List) {
      return nestedData;
    }

    if (nestedData is Map<String, dynamic>) {
      final nested =
          nestedData['listings'] ??
          nestedData['items'] ??
          nestedData['results'] ??
          nestedData['rows'];
      if (nested is List) {
        return nested;
      }
    }

    return null;
  }

  PaginationModel _parsePagination({
    required Map<String, dynamic> payload,
    required int page,
    required int limit,
    required int listingsCount,
  }) {
    final rawPagination = payload['pagination'];
    final paginationMap = rawPagination is Map<String, dynamic>
        ? rawPagination
        : payload;

    final total =
        _readInt(paginationMap['total']) ??
        _readInt(payload['total']) ??
        listingsCount;
    final totalPages =
        _readInt(paginationMap['totalPages']) ??
        _readInt(paginationMap['total_pages']) ??
        _readInt(paginationMap['pages']) ??
        _readInt(payload['totalPages']) ??
        _readInt(payload['total_pages']) ??
        _readInt(payload['pages']) ??
        1;
    final hasNext =
        _readBool(paginationMap['hasNext']) ??
        _readBool(paginationMap['has_next']) ??
        _readBool(payload['hasNext']) ??
        _readBool(payload['has_next']) ??
        false;
    final hasPrev =
        _readBool(paginationMap['hasPrev']) ??
        _readBool(paginationMap['has_prev']) ??
        _readBool(payload['hasPrev']) ??
        _readBool(payload['has_prev']) ??
        (page > 1);

    return PaginationModel(
      page: _readInt(paginationMap['page']) ?? page,
      limit: _readInt(paginationMap['limit']) ?? limit,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return null;
  }

  ServerException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ServerException(
        message: 'Connection timeout. Please try again.',
        code: 'TIMEOUT',
        statusCode: null,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return ServerException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
        statusCode: null,
      );
    }

    if (e.response != null) {
      final data = e.response!.data;
      String? message;

      if (data is Map<String, dynamic>) {
        message = data['message'] as String?;
        if (message == null && data['error'] != null) {
          if (data['error'] is String) {
            message = data['error'] as String;
          } else if (data['error'] is List &&
              (data['error'] as List).isNotEmpty) {
            final firstError = (data['error'] as List).first;
            if (firstError is Map && firstError['message'] != null) {
              message = firstError['message'] as String;
            }
          }
        }
      }

      return ServerException(
        message: message ?? 'Server error occurred',
        code: 'SERVER_ERROR',
        statusCode: e.response?.statusCode,
      );
    }

    return ServerException(
      message: e.message ?? 'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
      statusCode: null,
    );
  }
}
