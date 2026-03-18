import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/listing.dart';
import '../../../home/domain/entities/pagination.dart';
import '../../domain/entities/listing_pending_trade_offer.dart';
import '../../domain/entities/user_review_summary.dart';
import '../../domain/repositories/listing_detail_repository.dart';
import '../datasources/listing_detail_remote_datasource.dart';
import '../models/listing_trade_offer_model.dart';
import '../models/report_dto.dart';

/// Listing detail repository implementation
/// Converts DTOs to entities and maps exceptions to failures
class ListingDetailRepositoryImpl implements ListingDetailRepository {
  final ListingDetailRemoteDataSource remoteDataSource;

  ListingDetailRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Listing>> getListingById({required String id}) async {
    try {
      final response = await remoteDataSource.getListingById(id: id);
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ({List<Listing> listings, Pagination pagination})>>
  getMyListings({required int page, int limit = 20}) async {
    try {
      final response = await remoteDataSource.getMyListings(
        page: page,
        limit: limit,
      );

      final listings = response.listings
          .map((listing) => listing.toEntity())
          .toList();
      final pagination = response.pagination.toEntity();

      return Right((listings: listings, pagination: pagination));
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
          message: 'Failed to parse listings response',
          code: 'INVALID_RESPONSE',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> buyNow({required String listingId}) async {
    try {
      await remoteDataSource.buyNow(listingId: listingId);
      return Right(true);
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserReviewSummary>> getUserReviews({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await remoteDataSource.getUserReviews(
        userId: userId,
        page: page,
        limit: limit,
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
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'Failed to parse reviews response',
          code: 'INVALID_RESPONSE',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> deleteListing({
    required String listingId,
  }) async {
    try {
      await remoteDataSource.deleteListing(listingId: listingId);
      return const Right(true);
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    try {
      final message = await remoteDataSource.submitReport(
        request: CreateReportRequestModel(
          targetType: targetType,
          targetId: targetId,
          reason: reason,
          description: description,
        ),
      );
      return Right(message);
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ListingPendingTradeOffer?>>
  getPendingTradeOfferForListing({required String listingId}) async {
    try {
      final trades = await remoteDataSource.getListingPendingTrades(
        listingId: listingId,
      );

      if (trades.isEmpty) {
        return const Right(null);
      }

      final first = trades.first;
      if (first is ListingTradeOfferModel) {
        return Right(first.toEntity());
      }

      return const Right(null);
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }
}
