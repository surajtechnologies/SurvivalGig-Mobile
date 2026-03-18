import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/trade_offer.dart';
import '../../domain/repositories/make_offer_repository.dart';
import '../datasources/make_offer_remote_datasource.dart';
import '../models/trade_offer_model.dart';

/// Make offer repository implementation
class MakeOfferRepositoryImpl implements MakeOfferRepository {
  final MakeOfferRemoteDataSource remoteDataSource;

  MakeOfferRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CreatedTrade>> createTradeOffer({
    required TradeOfferRequest request,
  }) async {
    try {
      final requestModel = TradeOfferRequestModel.fromEntity(request);
      final response = await remoteDataSource.createTradeOffer(
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadImages({
    required List<String> base64Images,
  }) async {
    try {
      final urls = await remoteDataSource.uploadImages(
        base64Images: base64Images,
      );
      return Right(urls);
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
}
