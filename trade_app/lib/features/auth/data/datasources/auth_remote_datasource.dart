import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/device_token_dto.dart';
import '../models/facebook_auth_dto.dart';
import '../models/google_auth_dto.dart';
import '../models/login_dto.dart';
import '../models/register_dto.dart';

/// Auth remote datasource
/// Responsible for making API calls only
/// NO business logic, NO domain entities
abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<LoginResponseModel> loginWithGoogle(
    GoogleMobileAuthRequestModel request,
  );
  Future<LoginResponseModel> loginWithFacebook(
    FacebookMobileAuthRequestModel request,
  );
  Future<RegisterResponseModel> register(RegisterRequestModel request);
  Future<String> forgotPassword(String email);
  Future<List<String>> uploadProfileImage({required List<String> base64Images});
  Future<DeviceTokenResponseModel> registerDeviceToken(
    DeviceTokenRequestModel request,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      return _parseLoginResponse(response, defaultErrorCode: 'LOGIN_FAILED');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<LoginResponseModel> loginWithGoogle(
    GoogleMobileAuthRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.mobileGoogle,
        data: request.toJson(),
      );

      return _parseLoginResponse(
        response,
        defaultErrorCode: 'GOOGLE_LOGIN_FAILED',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<LoginResponseModel> loginWithFacebook(
    FacebookMobileAuthRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.mobileFacebook,
        data: request.toJson(),
      );

      return _parseLoginResponse(
        response,
        defaultErrorCode: 'FACEBOOK_LOGIN_FAILED',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Check if response has success field
        if (data is Map<String, dynamic>) {
          // Handle success: true with user at root level
          if (data['success'] == true && data['user'] != null) {
            return RegisterResponseModel.fromJson(data);
          }
          // Handle success: true with data wrapper
          if (data['success'] == true && data['data'] != null) {
            return RegisterResponseModel.fromJson(
              data['data'] as Map<String, dynamic>,
            );
          }
          // Handle direct response format (user at root, no success field)
          if (data['user'] != null) {
            return RegisterResponseModel.fromJson(data);
          }
        }

        throw ServerException(
          message: 'Invalid response format',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Registration failed',
          code: response.data['code'] ?? 'REGISTRATION_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> forgotPassword(String email) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            return data['message'] ?? 'Password reset email sent successfully';
          }
          if (data['success'] == false) {
            throw ServerException(
              message: data['message'] ?? 'Failed to send password reset email',
              code: 'FORGOT_PASSWORD_FAILED',
              statusCode: response.statusCode,
            );
          }
        }

        return 'Password reset email sent successfully';
      } else {
        throw ServerException(
          message:
              response.data['message'] ?? 'Failed to send password reset email',
          code: response.data['code'] ?? 'FORGOT_PASSWORD_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<String>> uploadProfileImage({
    required List<String> base64Images,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints
            .uploads, // Changed to plural /uploads to match post_listing
        data: {'images': base64Images},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Parse response similar to post_listing_remote_datasource.dart
        if (data is Map<String, dynamic>) {
          // Check for "data" wrapper with "images" list
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

          // Fallback/Legacy parsing if structure is different
          if (data['urls'] is List) {
            return (data['urls'] as List).map((e) => e.toString()).toList();
          }
        }

        throw ServerException(
          message: 'No URLs returned from upload',
          code: 'UPLOAD_FAILED',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Image upload failed',
          code: response.data['code'] ?? 'UPLOAD_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<DeviceTokenResponseModel> registerDeviceToken(
    DeviceTokenRequestModel request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.deviceToken,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          return DeviceTokenResponseModel.fromJson(data);
        }

        throw ServerException(
          message: 'Invalid response format',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Device token registration failed',
          code: response.data['code'] ?? 'DEVICE_TOKEN_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  LoginResponseModel _parseLoginResponse(
    Response response, {
    required String defaultErrorCode,
  }) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        // Handle success: true with accessToken and user at root level
        if (data['success'] == true &&
            data['user'] != null &&
            data['accessToken'] != null) {
          return LoginResponseModel.fromJson(data);
        }

        // Handle success: true with data wrapper
        if (data['success'] == true && data['data'] != null) {
          return LoginResponseModel.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }

        // Handle direct response format (user at root, no success field)
        if (data['user'] != null && data['accessToken'] != null) {
          return LoginResponseModel.fromJson(data);
        }

        // Handle success: false - throw error with message
        if (data['success'] == false) {
          throw ServerException(
            message: data['message'] ?? 'Login failed',
            code: defaultErrorCode,
            statusCode: response.statusCode,
          );
        }
      }

      throw ServerException(
        message: 'Invalid response format',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    String message = 'Login failed';
    String code = defaultErrorCode;
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
      code = data['code'] ?? code;
    }

    throw ServerException(
      message: message,
      code: code,
      statusCode: response.statusCode,
    );
  }

  /// Handle Dio errors and convert to domain exceptions
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timeout. Please try again.',
          code: 'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection',
          code: 'NO_INTERNET',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        String message = 'An error occurred';
        String code = 'UNKNOWN_ERROR';

        if (data is Map<String, dynamic>) {
          message = data['message'] ?? message;
          code = data['code'] ?? code;
        }

        return ServerException(
          message: message,
          code: code,
          statusCode: statusCode,
          data: data is Map<String, dynamic> ? data : null,
        );
      default:
        return ServerException(
          message: error.message ?? 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        );
    }
  }
}
