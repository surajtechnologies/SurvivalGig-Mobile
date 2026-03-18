import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

/// Wallet repository implementation
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, WalletSummary>> getWallet() async {
    try {
      final response = await remoteDataSource.getWallet();
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
  Future<Either<Failure, List<WalletTransaction>>> getWalletTransactions({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await remoteDataSource.getWalletTransactions(
        page: page,
        limit: limit,
      );
      return Right(
        response.transactions
            .map((transaction) => transaction.toEntity())
            .toList(),
      );
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
