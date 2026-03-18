import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/trade_offer_model.dart';

/// Make offer remote datasource
/// Responsible for making API calls only
abstract class MakeOfferRemoteDataSource {
  /// Create a trade offer
  Future<CreatedTradeModel> createTradeOffer({
    required TradeOfferRequestModel request,
  });

  /// Upload images for item offer
  Future<List<String>> uploadImages({
    required List<String> base64Images,
  });
}

class MakeOfferRemoteDataSourceImpl implements MakeOfferRemoteDataSource {
  final DioClient dioClient;

  MakeOfferRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<CreatedTradeModel> createTradeOffer({
    required TradeOfferRequestModel request,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.trades,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Handle response format: { success: true, trade: {...} }
          if (data['success'] == true && data['trade'] != null) {
            return CreatedTradeModel.fromJson(data['trade'] as Map<String, dynamic>);
          }

          // Fallback: direct trade object
          if (data['id'] != null) {
            return CreatedTradeModel.fromJson(data);
          }

          throw ServerException(
            message: _extractErrorMessage(data) ?? 'Failed to create trade offer',
            code: 'CREATE_TRADE_FAILED',
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
          message: response.data['message'] ?? 'Failed to create trade offer',
          code: response.data['code'] ?? 'CREATE_TRADE_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<String>> uploadImages({
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
                return urls;
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
}
