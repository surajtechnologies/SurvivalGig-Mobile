/// Base class for all data layer exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Server exception (API errors)
class ServerException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? data;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
    this.data,
  });

  @override
  String toString() =>
      'ServerException(message: $message, code: $code, statusCode: $statusCode)';
}

/// Cache exception (local storage errors)
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
  });
}

/// Network exception (connectivity issues)
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code = 'NO_INTERNET',
  });
}
