import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/categories_response_model.dart';
import '../models/listings_response_model.dart';
import '../models/pincode_lookup_response_model.dart';

/// Home remote datasource
/// Responsible for making API calls only
/// NO business logic, NO domain entities
abstract class HomeRemoteDataSource {
  /// Fetch all categories from API
  Future<CategoriesResponseModel> getCategories();

  /// Fetch paginated listings from API
  Future<ListingsResponseModel> getListings({
    required int page,
    int limit = 20,
    String? categoryId,
    String? search,
    String? location,
    String? intent,
  });

  /// Fetch city details from US pincode.
  Future<PincodeLookupResponseModel> getLocationByPincode({
    required String pincode,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<CategoriesResponseModel> getCategories() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.categories);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Handle success response
          if (data['success'] == true || data['status'] == 'success') {
            return CategoriesResponseModel.fromJson(data);
          }

          // Handle failure response
          if (data['success'] == false || data['status'] == 'failure') {
            throw ServerException(
              message:
                  _extractErrorMessage(data) ?? 'Failed to fetch categories',
              code: 'CATEGORIES_FAILED',
              statusCode: response.statusCode,
            );
          }
        }

        throw ServerException(
          message: 'Invalid response format',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch categories',
          code: response.data['code'] ?? 'CATEGORIES_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ListingsResponseModel> getListings({
    required int page,
    int limit = 20,
    String? categoryId,
    String? search,
    String? location,
    String? intent,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }

      // Search requests should not include intent filter.
      if ((search == null || search.isEmpty) &&
          intent != null &&
          intent.isNotEmpty) {
        queryParams['intent'] = intent;
      }

      final response = await dioClient.dio.get(
        ApiEndpoints.listings,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Handle success response
          if (data['success'] == true || data['listings'] != null) {
            return ListingsResponseModel.fromJson(data);
          }

          // Handle failure response
          if (data['success'] == false) {
            throw ServerException(
              message: _extractErrorMessage(data) ?? 'Failed to fetch listings',
              code: 'LISTINGS_FAILED',
              statusCode: response.statusCode,
            );
          }
        }

        throw ServerException(
          message: 'Invalid response format',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch listings',
          code: response.data['code'] ?? 'LISTINGS_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PincodeLookupResponseModel> getLocationByPincode({
    required String pincode,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.usPincodeLookup(pincode),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = PincodeLookupResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (model.places.isEmpty || model.places.first.placeName.isEmpty) {
          throw const ServerException(
            message: 'City not found for this pincode',
            code: 'PINCODE_CITY_NOT_FOUND',
            statusCode: 404,
          );
        }

        return model;
      }

      throw ServerException(
        message: 'Invalid pincode lookup response',
        code: 'PINCODE_LOOKUP_INVALID_RESPONSE',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Extract error message from API response
  String? _extractErrorMessage(Map<String, dynamic> data) {
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

  /// Handle Dio errors and convert to ServerException
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
      if (e.response?.statusCode == 404 &&
          e.requestOptions.uri.toString().contains('api.zippopotam.us')) {
        return const ServerException(
          message: 'Invalid pincode. Please enter a valid US pincode.',
          code: 'PINCODE_NOT_FOUND',
          statusCode: 404,
        );
      }

      final data = e.response!.data;
      String? message;

      if (data is Map<String, dynamic>) {
        message = _extractErrorMessage(data);
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
