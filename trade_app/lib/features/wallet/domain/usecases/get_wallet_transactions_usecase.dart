import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_transaction.dart';
import '../repositories/wallet_repository.dart';

/// Use case for fetching wallet transactions
class GetWalletTransactionsUseCase {
  final WalletRepository repository;

  GetWalletTransactionsUseCase({required this.repository});

  Future<Either<Failure, List<WalletTransaction>>> call({
    required int page,
    required int limit,
  }) async {
    if (page < 1) {
      return const Left(
        ValidationFailure(
          message: 'Page number must be at least 1',
          code: 'INVALID_PAGE',
        ),
      );
    }

    if (limit < 1 || limit > 100) {
      return const Left(
        ValidationFailure(
          message: 'Limit must be between 1 and 100',
          code: 'INVALID_LIMIT',
        ),
      );
    }

    return repository.getWalletTransactions(page: page, limit: limit);
  }
}
