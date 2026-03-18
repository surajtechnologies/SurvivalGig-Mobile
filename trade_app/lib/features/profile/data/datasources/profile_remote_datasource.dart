import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/profile_model.dart';
import '../models/profile_review_model.dart';

/// Profile remote datasource
/// Responsible for API calls only
abstract class ProfileRemoteDataSource {
  /// Get current authenticated user profile
  Future<ProfileModel> getProfile();

  /// Upload profile image to upload endpoint and return image URL
  Future<String> uploadProfileImage({required List<String> base64Images});

  /// Get current user ratings and reviews
  Future<List<ProfileReviewModel>> getProfileReviews({
    required String userId,
    required int page,
    required int limit,
  });

  /// Persist profile image URL on user profile
  Future<ProfileModel> updateProfileImage({required String imageUrl});

  /// Upload ID document for current user verification
  Future<String> verifyProfile({required String filePath});

  /// Send forgot-password email
  Future<String> sendPasswordResetEmail({required String email});

  /// Reset password with token and new password
  Future<String> resetPassword({
    required String token,
    required String password,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient dioClient;

  ProfileRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.currentUser);

      if (response.statusCode == 200) {
        try {
          return ProfileModel.fromResponse(response.data);
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
            _extractErrorMessage(response.data) ?? 'Failed to load profile',
        code: 'PROFILE_FETCH_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> uploadProfileImage({
    required List<String> base64Images,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.uploads,
        data: {'images': base64Images},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final imageUrl = _extractImageUrl(response.data);
        if (imageUrl != null) {
          return imageUrl;
        }

        throw ServerException(
          message: 'No URLs returned from upload',
          code: 'UPLOAD_FAILED',
          statusCode: response.statusCode,
        );
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ??
            'Failed to upload profile image',
        code: 'UPLOAD_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<ProfileReviewModel>> getProfileReviews({
    required String userId,
    required int page,
    required int limit,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.getUserReviews(userId),
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return ProfileReviewModel.listFromResponse(response.data);
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ??
            'Failed to load user reviews',
        code: 'GET_USER_REVIEWS_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ProfileModel> updateProfileImage({required String imageUrl}) async {
    try {
      final response = await dioClient.dio.patch(
        ApiEndpoints.updateProfile,
        data: {'avatarUrl': imageUrl},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return ProfileModel.fromResponse(
            response.data,
            fallbackProfileImageUrl: imageUrl,
          );
        } on FormatException {
          // Fallback to fresh profile fetch if update response body is empty/different.
          return getProfile();
        }
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to update profile',
        code: 'PROFILE_UPDATE_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> sendPasswordResetEmail({required String email}) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(
              message:
                  _extractErrorMessage(data) ?? 'Failed to send reset email',
              code: 'FORGOT_PASSWORD_FAILED',
              statusCode: response.statusCode,
            );
          }

          final message = data['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }

        return 'Password reset email sent successfully';
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to send reset email',
        code: 'FORGOT_PASSWORD_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(
              message: _extractErrorMessage(data) ?? 'Failed to reset password',
              code: 'RESET_PASSWORD_FAILED',
              statusCode: response.statusCode,
            );
          }

          final message = data['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }

        return 'Password reset successful';
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ?? 'Failed to reset password',
        code: 'RESET_PASSWORD_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> verifyProfile({required String filePath}) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'idDocument': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await dioClient.dio.post(
        ApiEndpoints.uploadIdDocument,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _extractSuccessMessage(response.data) ??
            'Profile verification document uploaded successfully';
      }

      throw ServerException(
        message:
            _extractErrorMessage(response.data) ??
            'Failed to upload verification document',
        code: 'PROFILE_VERIFICATION_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String? _extractSuccessMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final responseData = data['data'];
    if (responseData is Map<String, dynamic>) {
      final nestedMessage = responseData['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
        return nestedMessage.trim();
      }
    }

    return null;
  }

  String? _extractImageUrl(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final responseData = data['data'];
    if (responseData is Map<String, dynamic>) {
      final images = responseData['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        if (first is Map<String, dynamic>) {
          final url = first['url'];
          if (url is String && url.trim().isNotEmpty) {
            return url.trim();
          }
        }
      }

      final url = responseData['url'];
      if (url is String && url.trim().isNotEmpty) {
        return url.trim();
      }
    }

    final urls = data['urls'];
    if (urls is List && urls.isNotEmpty) {
      final first = urls.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }

    final url = data['url'];
    if (url is String && url.trim().isNotEmpty) {
      return url.trim();
    }

    return null;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (data['message'] is String) {
      return data['message'] as String;
    }

    if (data['error'] is String) {
      return data['error'] as String;
    }

    if (data['error'] is List && (data['error'] as List).isNotEmpty) {
      final firstError = (data['error'] as List).first;
      if (firstError is Map && firstError['message'] is String) {
        return firstError['message'] as String;
      }
    }

    return null;
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException(
        message: 'Connection timeout. Please try again.',
        code: 'TIMEOUT',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    if (e.response != null) {
      return ServerException(
        message:
            _extractErrorMessage(e.response!.data) ?? 'Server error occurred',
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
