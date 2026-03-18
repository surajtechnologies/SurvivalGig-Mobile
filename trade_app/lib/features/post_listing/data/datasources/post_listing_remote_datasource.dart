import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/categories_response_model.dart';
import '../models/create_listing_model.dart';
import '../models/upload_image_model.dart';

/// Post listing remote datasource
/// Responsible for making API calls only
abstract class PostListingRemoteDataSource {
  /// Upload images as base64 strings and get URLs back
  Future<UploadImagesResponseModel> uploadImages({
    required List<String> base64Images,
  });

  /// Create a new listing with image URLs
  Future<CreateListingResponseModel> createListing({
    required CreateListingRequestModel request,
  });

  /// Get all categories
  Future<CategoriesResponseModel> getCategories();

  /// Get city name from US zipcode
  Future<String> getCityByZipcode({required String zipcode});
}

class PostListingRemoteDataSourceImpl implements PostListingRemoteDataSource {
  final DioClient dioClient;

  PostListingRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UploadImagesResponseModel> uploadImages({
    required List<String> base64Images,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.uploads,
        data: {'images': base64Images},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Extract URLs from response: {"data": {"images": [{"url": "..."}]}}
          final responseData = data['data'];
          if (responseData != null && responseData is Map<String, dynamic>) {
            final images = responseData['images'];
            if (images != null && images is List) {
              final urls = images
                  .map((img) => img['url'] as String?)
                  .where((url) => url != null)
                  .cast<String>()
                  .toList();

              if (urls.isNotEmpty) {
                return UploadImagesResponseModel(success: true, urls: urls);
              }
            }
          }

          throw ServerException(
            message: 'No URLs returned from upload',
            code: 'UPLOAD_FAILED',
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
          message: response.data['message'] ?? 'Failed to upload images',
          code: response.data['code'] ?? 'UPLOAD_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CreateListingResponseModel> createListing({
    required CreateListingRequestModel request,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.listings,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data['success'] == true ||
              data['listing'] != null ||
              data['data'] != null) {
            return CreateListingResponseModel.fromJson(data);
          }

          if (data['success'] == false) {
            throw ServerException(
              message: _extractErrorMessage(data) ?? 'Failed to create listing',
              code: 'CREATE_LISTING_FAILED',
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
          message: response.data['message'] ?? 'Failed to create listing',
          code: response.data['code'] ?? 'CREATE_LISTING_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

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

  @override
  Future<CategoriesResponseModel> getCategories() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.categories);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data['success'] == true || data['status'] == 'success') {
            return CategoriesResponseModel.fromJson(data);
          }

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
  Future<String> getCityByZipcode({required String zipcode}) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.usPincodeLookup(zipcode),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final places = data['places'];
        if (places is List && places.isNotEmpty) {
          final first = places.first;
          if (first is Map<String, dynamic>) {
            final city =
                first['place name'] as String? ?? first['placeName'] as String?;
            if (city != null && city.trim().isNotEmpty) {
              return city.trim();
            }
          }
        }

        throw const ServerException(
          message: 'City not found for this zipcode',
          code: 'ZIPCODE_CITY_NOT_FOUND',
          statusCode: 404,
        );
      }

      throw ServerException(
        message: 'Invalid zipcode lookup response',
        code: 'ZIPCODE_LOOKUP_INVALID_RESPONSE',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 &&
          e.requestOptions.uri.toString().contains('api.zippopotam.us')) {
        throw const ServerException(
          message: 'Invalid zipcode. Please enter a valid US zipcode.',
          code: 'ZIPCODE_NOT_FOUND',
          statusCode: 404,
        );
      }

      throw _handleDioError(e);
    }
  }
}
