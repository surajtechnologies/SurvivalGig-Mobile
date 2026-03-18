/// Base class for all domain failures
abstract class Failure {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });
}

/// Server failure (API errors, network issues)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });
}

/// Validation failure (invalid input)
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// Authentication failure (token expired, unauthorized)
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

/// Cache failure (local storage issues)
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

/// Network failure (no internet connection)
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code = 'NO_INTERNET',
  });
}
