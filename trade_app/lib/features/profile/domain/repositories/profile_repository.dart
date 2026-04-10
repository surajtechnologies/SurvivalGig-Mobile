import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../entities/profile_review.dart';

/// Profile repository contract
abstract class ProfileRepository {
  /// Get current user profile from API
  Future<Either<Failure, Profile>> getProfile();

  /// Upload and update current user profile image
  Future<Either<Failure, Profile>> uploadProfileImage({
    required String base64Image,
  });

  /// Get current user ratings and reviews.
  Future<Either<Failure, List<ProfileReview>>> getProfileReviews({
    required String userId,
    int page = 1,
    int limit = 10,
  });

  /// Submit ID document for profile verification
  Future<Either<Failure, String>> verifyProfile({required String filePath});

  /// Send password reset token email
  Future<Either<Failure, String>> sendPasswordResetEmail({
    required String email,
  });

  /// Reset password using token from email
  Future<Either<Failure, String>> resetPassword({
    required String token,
    required String password,
  });

  /// Delete current user account (soft-delete)
  Future<Either<Failure, String>> deleteAccount();
}
