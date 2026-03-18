import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/create_listing.dart';
import '../../domain/repositories/post_listing_repository.dart';
import '../datasources/post_listing_remote_datasource.dart';
import '../models/create_listing_model.dart';

/// Post listing repository implementation
/// Converts DTOs to entities and maps exceptions to failures
class PostListingRepositoryImpl implements PostListingRepository {
  final PostListingRemoteDataSource remoteDataSource;

  PostListingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<String>>> uploadImages({
    required List<String> base64Images,
  }) async {
    try {
      final response = await remoteDataSource.uploadImages(
        base64Images: base64Images,
      );
      return Right(response.urls);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred while uploading images',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CreatedListing>> createListing({
    required CreateListingRequest request,
  }) async {
    try {
      final requestModel = CreateListingRequestModel.fromEntity(request);
      final response = await remoteDataSource.createListing(
        request: requestModel,
      );
      return Right(response.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred while creating listing',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final response = await remoteDataSource.getCategories();
      return Right(response.categories.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred while fetching categories',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getCityByZipcode({
    required String zipcode,
  }) async {
    try {
      final city = await remoteDataSource.getCityByZipcode(zipcode: zipcode);
      return Right(city);
    } on ServerException catch (e) {
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
          message: 'An unexpected error occurred while fetching city',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }
}
