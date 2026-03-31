import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/device_token.dart';
import '../entities/user.dart';
import '../entities/auth_token.dart';

/// Authentication repository interface
/// This is the contract that data layer must implement
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, ({User user, AuthToken token})>> login({
    required String email,
    required String password,
  });

  /// Login with Google OAuth
  Future<Either<Failure, ({User user, AuthToken token})>> signInWithGoogle();

  /// Login with Facebook OAuth
  Future<Either<Failure, ({User user, AuthToken token})>> signInWithFacebook();

  /// Login with Apple OAuth
  Future<Either<Failure, ({User user, AuthToken token})>> signInWithApple();

  /// Register new user
  Future<Either<Failure, ({User user, AuthToken? token, String? message})>>
  register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? location,
    String? profileImage,
  });

  /// Request password reset
  Future<Either<Failure, String>> requestPasswordReset({required String email});

  /// Logout user
  Future<Either<Failure, void>> logout();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Get current user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Upload profile image
  Future<Either<Failure, String>> uploadProfileImage({
    required String base64Image,
  });

  /// Register FCM device token for push notifications
  Future<Either<Failure, DeviceToken>> registerDeviceToken({
    required String token,
    required String platform,
  });
}
