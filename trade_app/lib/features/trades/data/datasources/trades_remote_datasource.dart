import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/trade_message_model.dart';
import '../models/trade_detail_model.dart';
import '../models/trades_page_model.dart';

/// Trades remote datasource
/// Responsible for making API calls only
abstract class TradesRemoteDataSource {
  /// Get trades list
  Future<TradesPageModel> getTrades({required int page, required int limit});

  /// Get trade detail
  Future<TradeDetailModel> getTradeDetail({required String tradeId});

  /// Accept trade
  Future<void> acceptTrade({required String tradeId});

  /// Reject trade
  Future<void> rejectTrade({required String tradeId});

  /// Confirm trade
  Future<void> confirmTrade({required String tradeId});

  /// Submit review for a trade
  Future<void> submitTradeReview({
    required String tradeId,
    required int rating,
    required String comment,
  });

  /// Get trade messages
  Future<List<TradeMessageModel>> getTradeMessages({
    required String tradeId,
    int? page,
    int? limit,
    DateTime? since,
  });

  /// Send trade message
  Future<TradeMessageModel> sendTradeMessage({
    required String tradeId,
    required String content,
  });
}

class TradesRemoteDataSourceImpl implements TradesRemoteDataSource {
  final DioClient dioClient;

  TradesRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<TradesPageModel> getTrades({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.trades,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        try {
          return TradesPageModel.fromResponse(
            data: response.data,
            page: page,
            limit: limit,
          );
        } on FormatException {
          throw ServerException(
            message: 'Invalid response format',
            code: 'INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }
      }

      throw ServerException(
        message: _extractErrorMessage(response.data) ?? 'Failed to load trades',
        code: 'GET_TRADES_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TradeDetailModel> getTradeDetail({required String tradeId}) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.getTradeById(tradeId),
      );

      if (response.statusCode == 200) {
        try {
          return TradeDetailModel.fromResponse(response.data);
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
            'Failed to load trade detail',
        code: 'GET_TRADE_DETAIL_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> acceptTrade({required String tradeId}) async {
    await _patchAction(
      ApiEndpoints.acceptTrade(tradeId),
      successCode: 'ACCEPT_TRADE_FAILED',
    );
  }

  @override
  Future<void> rejectTrade({required String tradeId}) async {
    await _patchAction(
      ApiEndpoints.rejectTrade(tradeId),
      successCode: 'REJECT_TRADE_FAILED',
    );
  }

  @override
  Future<void> confirmTrade({required String tradeId}) async {
    await _patchAction(
      ApiEndpoints.confirmTrade(tradeId),
      successCode: 'CONFIRM_TRADE_FAILED',
    );
  }

  @override
  Future<void> submitTradeReview({
    required String tradeId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.reviewTrade(tradeId),
        data: {'rating': rating, 'comment': comment},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to submit review',
        code: 'SUBMIT_REVIEW_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<TradeMessageModel>> getTradeMessages({
    required String tradeId,
    int? page,
    int? limit,
    DateTime? since,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (page != null) queryParameters['page'] = page;
      if (limit != null) queryParameters['limit'] = limit;
      if (since != null) queryParameters['since'] = since.toIso8601String();

      final response = await dioClient.dio.get(
        ApiEndpoints.tradeMessages(tradeId),
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: Options(
          extra: {'skipLoading': since != null},
        ),
      );

      if (response.statusCode == 200) {
        try {
          return TradeMessageModel.listFromResponse(response.data);
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
            _extractErrorMessage(response.data) ?? 'Failed to load messages',
        code: 'GET_MESSAGES_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TradeMessageModel> sendTradeMessage({
    required String tradeId,
    required String content,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.tradeMessages(tradeId),
        data: {'content': content},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return TradeMessageModel.fromResponse(response.data);
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
            _extractErrorMessage(response.data) ?? 'Failed to send message',
        code: 'SEND_MESSAGE_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> _patchAction(String path, {required String successCode}) async {
    try {
      final response = await dioClient.dio.patch(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw ServerException(
        message: _extractErrorMessage(response.data) ?? 'Request failed',
        code: successCode,
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

    final directMessage = _extractMapMessage(data);
    if (directMessage != null) {
      return directMessage;
    }

    final error = data['error'];
    final errorMessage = _extractDynamicMessage(error);
    if (errorMessage != null) {
      return errorMessage;
    }

    final errors = data['errors'];
    final errorsMessage = _extractDynamicMessage(errors);
    if (errorsMessage != null) {
      return errorsMessage;
    }

    final details = data['details'];
    final detailsMessage = _extractDynamicMessage(details);
    if (detailsMessage != null) {
      return detailsMessage;
    }

    return null;
  }

  String? _extractDynamicMessage(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is Map<String, dynamic>) {
      return _extractMapMessage(value);
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map<String, dynamic>) {
        return _extractMapMessage(first);
      }
    }

    return null;
  }

  String? _extractMapMessage(Map<String, dynamic> value) {
    final message =
        value['message'] ??
        value['msg'] ??
        value['error_description'] ??
        value['detail'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
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
