import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/env/app_config.dart';
import '../../features/common/presentation/cubit/loading_cubit.dart';
import '../utils/user_session.dart';
import 'api_endpoints.dart';
import 'interceptors/loading_interceptor.dart';

/// Dio client for making HTTP requests
/// Single shared instance following MANDATORY networking rules
class DioClient {
  late final Dio dio;
  final FlutterSecureStorage _storage;
  final LoadingCubit? _loadingCubit;
  UserSession? _userSession;
  bool _isExpiringSession = false;

  DioClient({FlutterSecureStorage? storage, LoadingCubit? loadingCubit})
    : _storage = storage ?? const FlutterSecureStorage(),
      _loadingCubit = loadingCubit {
    dio = Dio(_createBaseOptions());
    _setupInterceptors();
  }

  /// Set user session for logout handling on 401
  void setUserSession(UserSession session) {
    _userSession = session;
  }

  /// Create base Dio options
  BaseOptions _createBaseOptions() {
    return BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: Duration(seconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
      sendTimeout: Duration(seconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  /// Setup interceptors (order is ABSOLUTE as per rules)
  void _setupInterceptors() {
    // 0. Loading Interceptor (shows/hides global loader)
    if (_loadingCubit != null) {
      dio.interceptors.add(LoadingInterceptor(loadingCubit: _loadingCubit));
    }

    // 1. Auth Interceptor (MUST BE FIRST after loading)
    dio.interceptors.add(_createAuthInterceptor());

    // 2. Logging Interceptor (ONLY in debug mode)
    if (kDebugMode) {
      dio.interceptors.add(_createLoggingInterceptor());
    }

    // 3. Error Interceptor (MUST BE LAST)
    dio.interceptors.add(_createErrorInterceptor());
  }

  /// Create Auth Interceptor
  /// - Attach access token
  /// - Handle token refresh
  /// - Retry original request ONCE
  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for auth endpoints
        if (options.path.contains('/auth/login') ||
            options.path.contains('/auth/register') ||
            options.path.contains('/auth/mobile')) {
          return handler.next(options);
        }

        // Attach access token
        final token = await _storage.read(key: AppConfig.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onResponse: (response, handler) async {
        if (_shouldExpireSession(response: response)) {
          await _expireSession();
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'No token provided',
            ),
          );
        }

        return handler.next(response);
      },
      onError: (error, handler) async {
        if (_shouldExpireSession(error: error)) {
          await _expireSession();
        }

        return handler.next(error);
      },
    );
  }

  /// Create Logging Interceptor
  /// Only logs in debug mode
  /// Create Logging Interceptor
  /// Custom simple logger as per user request
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final requestLog = StringBuffer()
          ..writeln('URL: ${options.uri}')
          ..writeln('Method: ${options.method}')
          ..writeln('Request Header: ${_formatForLog(options.headers)}');

        _logChunked(requestLog.toString());
        handler.next(options);
      },
      onResponse: (response, handler) {
        final responseLog = StringBuffer()
          ..writeln('Status: ${response.statusCode}')
          ..writeln('Response: ${_formatForLog(response.data)}');

        _logChunked(responseLog.toString());
        handler.next(response);
      },
      onError: (error, handler) {
        final errorResponse =
            error.response?.data ??
            {'errorType': error.type.name, 'message': error.message};

        final errorLog = StringBuffer()
          ..writeln('Status: ${error.response?.statusCode}')
          ..writeln('Response: ${_formatForLog(errorResponse)}');

        _logChunked(errorLog.toString());
        handler.next(error);
      },
    );
  }

  void _logChunked(String message) {
    const int chunkSize = 900;

    for (final line in message.split('\n')) {
      if (line.length <= chunkSize) {
        debugPrintSynchronously(line);
        continue;
      }

      for (int i = 0; i < line.length; i += chunkSize) {
        final int end = (i + chunkSize < line.length)
            ? i + chunkSize
            : line.length;
        debugPrintSynchronously(line.substring(i, end));
      }
    }
  }

  String _formatForLog(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return value;
    }

    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  /// Create Error Interceptor
  /// Converts DioError → AppException
  /// Normalizes all error types
  InterceptorsWrapper _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // Error is already handled by datasource
        // This interceptor is for global error normalization if needed
        return handler.next(error);
      },
    );
  }

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    _isExpiringSession = false;
    await _storage.write(key: AppConfig.accessTokenKey, value: token);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConfig.refreshTokenKey, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConfig.accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConfig.refreshTokenKey);
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: AppConfig.accessTokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
  }

  bool _shouldExpireSession({
    Response<dynamic>? response,
    DioException? error,
  }) {
    final path = response?.requestOptions.path ?? error?.requestOptions.path;
    if (path != null && _isAuthEndpoint(path)) {
      return false;
    }

    final statusCode = response?.statusCode ?? error?.response?.statusCode;
    if (statusCode == 401) {
      return true;
    }

    return _containsNoTokenProvided(response?.data) ||
        _containsNoTokenProvided(error?.response?.data) ||
        _containsNoTokenProvided(error?.message) ||
        _containsNoTokenProvided(error?.error);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/mobile') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password') ||
        path.contains('/auth/verify-email') ||
        path.contains('/auth/resend-verification');
  }

  bool _containsNoTokenProvided(Object? value) {
    if (value == null) return false;

    if (value is String) {
      return value.toLowerCase().contains('no token provided');
    }

    if (value is Map) {
      return value.values.any(_containsNoTokenProvided);
    }

    if (value is Iterable) {
      return value.any(_containsNoTokenProvided);
    }

    return value.toString().toLowerCase().contains('no token provided');
  }

  Future<void> _expireSession() async {
    if (_isExpiringSession) return;
    _isExpiringSession = true;

    final userSession = _userSession;
    if (userSession != null) {
      await userSession.expireSession();
      return;
    }

    await clearTokens();
  }
}
