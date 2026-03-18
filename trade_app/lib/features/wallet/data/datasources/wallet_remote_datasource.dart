import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transactions_response_model.dart';

/// Wallet remote datasource
/// Responsible for API calls only
abstract class WalletRemoteDataSource {
  /// Get wallet summary
  Future<WalletModel> getWallet();

  /// Get wallet transactions
  Future<WalletTransactionsResponseModel> getWalletTransactions({
    required int page,
    required int limit,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final DioClient dioClient;

  WalletRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<WalletModel> getWallet() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.wallet);

      if (response.statusCode == 200) {
        try {
          return WalletModel.fromResponse(response.data);
        } on FormatException {
          throw ServerException(
            message: 'Invalid response format',
            code: 'INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }
      }

      throw ServerException(
        message: _extractErrorMessage(response.data) ?? 'Failed to load wallet',
        code: 'WALLET_FETCH_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<WalletTransactionsResponseModel> getWalletTransactions({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        try {
          return WalletTransactionsResponseModel.fromResponse(response.data);
        } on FormatException {
          throw ServerException(
            message: 'Invalid response format',
            code: 'INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ??
            'Failed to load wallet transactions',
        code: 'WALLET_TRANSACTIONS_FETCH_FAILED',
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
