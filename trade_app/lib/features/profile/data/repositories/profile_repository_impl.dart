import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_review.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Profile repository implementation
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Profile>> getProfile() async {
    try {
      final response = await remoteDataSource.getProfile();
      return Right(response.toEntity());
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
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Profile>> uploadProfileImage({
    required String base64Image,
  }) async {
    try {
      final uploadedImageUrl = await remoteDataSource.uploadProfileImage(
        base64Images: [base64Image],
      );

      final response = await remoteDataSource.updateProfileImage(
        imageUrl: uploadedImageUrl,
      );

      return Right(response.toEntity());
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
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ProfileReview>>> getProfileReviews({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await remoteDataSource.getProfileReviews(
        userId: userId,
        page: page,
        limit: limit,
      );

      return Right(response.map((review) => review.toEntity()).toList());
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
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> verifyProfile({
    required String filePath,
  }) async {
    try {
      final message = await remoteDataSource.verifyProfile(filePath: filePath);
      return Right(message);
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
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      final message = await remoteDataSource.sendPasswordResetEmail(
        email: email,
      );
      return Right(message);
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
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final message = await remoteDataSource.resetPassword(
        token: token,
        password: password,
      );
      return Right(message);
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
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }
}
