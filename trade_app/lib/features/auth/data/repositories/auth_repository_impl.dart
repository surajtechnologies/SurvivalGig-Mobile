import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/user_session.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/device_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/facebook_sign_in_local_datasource.dart';
import '../datasources/google_sign_in_local_datasource.dart';
import '../models/device_token_dto.dart';
import '../models/facebook_auth_dto.dart';
import '../models/google_auth_dto.dart';
import '../models/login_dto.dart';
import '../models/register_dto.dart';

/// Auth repository implementation
/// Implements domain repository interface
/// Converts DTO ↔ Entity
/// Maps exceptions → failures
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FacebookSignInLocalDataSource facebookSignInLocalDataSource;
  final GoogleSignInLocalDataSource googleSignInLocalDataSource;
  final DioClient dioClient;
  final UserSession userSession;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.facebookSignInLocalDataSource,
    required this.googleSignInLocalDataSource,
    required this.dioClient,
    required this.userSession,
  });

  void _printGoogleIdTokenUntruncated(String idToken) {
    if (!kDebugMode) return;

    const int chunkSize = 800;
    debugPrintSynchronously('GOOGLE_ID_TOKEN_START');
    for (int start = 0; start < idToken.length; start += chunkSize) {
      final int end = (start + chunkSize < idToken.length)
          ? start + chunkSize
          : idToken.length;
      debugPrintSynchronously(idToken.substring(start, end));
    }
    debugPrintSynchronously('GOOGLE_ID_TOKEN_END');
  }

  @override
  Future<Either<Failure, ({User user, AuthToken token})>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Create request model (DTO)
      final request = LoginRequestModel(email: email, password: password);

      // Call datasource
      final response = await remoteDataSource.login(request);

      // Save tokens securely (uses Keychain on iOS, EncryptedSharedPreferences on Android)
      await dioClient.saveAccessToken(response.accessToken);
      await dioClient.saveRefreshToken(response.refreshToken);

      // Convert DTO to domain entity
      final user = response.user.toEntity();

      // Store user in session for global access
      await userSession.setUser(user);

      final token = AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return Right((user: user, token: token));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected login error: $e\n$stackTrace');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ({User user, AuthToken token})>>
  signInWithGoogle() async {
    try {
      final idToken = await googleSignInLocalDataSource.getIdToken();
      final request = GoogleMobileAuthRequestModel(idToken: idToken);
      final response = await remoteDataSource.loginWithGoogle(request);

      await dioClient.saveAccessToken(response.accessToken);
      await dioClient.saveRefreshToken(response.refreshToken);

      _printGoogleIdTokenUntruncated(idToken);

      final user = response.user.toEntity();
      await userSession.setUser(user);

      final token = AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return Right((user: user, token: token));
    } on CacheException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected Google login error: $e\n$stackTrace');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ({User user, AuthToken token})>>
  signInWithFacebook() async {
    try {
      final accessToken = await facebookSignInLocalDataSource.getAccessToken();
      final request = FacebookMobileAuthRequestModel(accessToken: accessToken);
      final response = await remoteDataSource.loginWithFacebook(request);

      await dioClient.saveAccessToken(response.accessToken);
      await dioClient.saveRefreshToken(response.refreshToken);

      final user = response.user.toEntity();
      await userSession.setUser(user);

      final token = AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return Right((user: user, token: token));
    } on CacheException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected Facebook login error: $e\n$stackTrace');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ({User user, AuthToken? token, String? message})>>
  register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? location,
    String? profileImage,
  }) async {
    try {
      // Create request model (DTO)
      final request = RegisterRequestModel(
        email: email,
        password: password,
        name: name,
        phone: phone,
        location: location,
        profileImage: profileImage,
      );

      // Call datasource
      final response = await remoteDataSource.register(request);

      // Save tokens only if provided
      if (response.token != null) {
        await dioClient.saveAccessToken(response.token!);
      }
      if (response.refreshToken != null) {
        await dioClient.saveRefreshToken(response.refreshToken!);
      }

      // Convert DTO to domain entity
      final user = response.user.toEntity();
      final AuthToken? token =
          (response.token != null && response.refreshToken != null)
          ? AuthToken(
              accessToken: response.token!,
              refreshToken: response.refreshToken!,
            )
          : null;

      return Right((user: user, token: token, message: response.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 409) {
        return Left(
          ServerFailure(
            message: 'This email is already registered',
            code: 'EMAIL_EXISTS',
            statusCode: e.statusCode,
          ),
        );
      }
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected register error: $e\n$stackTrace');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final message = await remoteDataSource.forgotPassword(email);
      return Right(message);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected password reset error: $e\n$stackTrace');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await dioClient.clearTokens();
      await userSession.clearUser();
      await googleSignInLocalDataSource.signOut();
      await facebookSignInLocalDataSource.signOut();
      return const Right(null);
    } catch (e) {
      debugPrint('Logout error: $e');
      return Left(
        CacheFailure(message: 'Failed to logout', code: 'LOGOUT_ERROR'),
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await dioClient.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    // TODO: Implement get current user from API
    return Left(
      ServerFailure(message: 'Not implemented', code: 'NOT_IMPLEMENTED'),
    );
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage({
    required String base64Image,
  }) async {
    try {
      final urls = await remoteDataSource.uploadProfileImage(
        base64Images: [base64Image],
      );

      if (urls.isNotEmpty) {
        return Right(urls.first);
      }

      return const Left(
        ServerFailure(
          message: 'Image upload returned no URL',
          code: 'UPLOAD_FAILED',
        ),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected profile upload error: $e\n$stackTrace');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred during image upload',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, DeviceToken>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final request = DeviceTokenRequestModel(
        token: token,
        platform: platform,
      );

      final response = await remoteDataSource.registerDeviceToken(request);

      if (response.success && response.deviceToken != null) {
        final deviceToken = DeviceToken(
          id: response.deviceToken!.id,
          token: response.deviceToken!.token,
          platform: response.deviceToken!.platform,
          createdAt: DateTime.tryParse(response.deviceToken!.createdAt),
        );

        return Right(deviceToken);
      }

      return Left(
        ServerFailure(
          message: response.message.isNotEmpty
              ? response.message
              : 'Device token registration failed',
          code: 'DEVICE_TOKEN_FAILED',
        ),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected device token registration error: $e\n$stackTrace');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }
}
