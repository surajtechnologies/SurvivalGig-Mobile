import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/trade_detail.dart';
import '../../domain/entities/trade_message.dart';
import '../../domain/entities/trades_page.dart';
import '../../domain/repositories/trades_repository.dart';
import '../datasources/trades_remote_datasource.dart';

/// Trades repository implementation
class TradesRepositoryImpl implements TradesRepository {
  final TradesRemoteDataSource remoteDataSource;

  TradesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, TradesPage>> getTrades({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await remoteDataSource.getTrades(
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, TradeDetail>> getTradeDetail({
    required String tradeId,
  }) async {
    try {
      final response = await remoteDataSource.getTradeDetail(tradeId: tradeId);
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> acceptTrade({required String tradeId}) async {
    return _performAction(() => remoteDataSource.acceptTrade(tradeId: tradeId));
  }

  @override
  Future<Either<Failure, bool>> rejectTrade({required String tradeId}) async {
    return _performAction(() => remoteDataSource.rejectTrade(tradeId: tradeId));
  }

  @override
  Future<Either<Failure, bool>> confirmTrade({required String tradeId}) async {
    return _performAction(
      () => remoteDataSource.confirmTrade(tradeId: tradeId),
    );
  }

  @override
  Future<Either<Failure, bool>> submitTradeReview({
    required String tradeId,
    required int rating,
    required String comment,
  }) async {
    return _performAction(
      () => remoteDataSource.submitTradeReview(
        tradeId: tradeId,
        rating: rating,
        comment: comment,
      ),
    );
  }

  @override
  Future<Either<Failure, List<TradeMessage>>> getTradeMessages({
    required String tradeId,
    int? page,
    int? limit,
    DateTime? since,
  }) async {
    try {
      final response = await remoteDataSource.getTradeMessages(
        tradeId: tradeId,
        page: page,
        limit: limit,
        since: since,
      );
      return Right(response.map((message) => message.toEntity()).toList());
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
  Future<Either<Failure, TradeMessage>> sendTradeMessage({
    required String tradeId,
    required String content,
  }) async {
    try {
      final response = await remoteDataSource.sendTradeMessage(
        tradeId: tradeId,
        content: content,
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
          message: 'An unexpected error occurred',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  Future<Either<Failure, bool>> _performAction(
    Future<void> Function() action,
  ) async {
    try {
      await action();
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
}
