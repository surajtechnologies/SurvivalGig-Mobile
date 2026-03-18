import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_summary.dart';
import '../entities/wallet_transaction.dart';

/// Wallet repository contract
abstract class WalletRepository {
  /// Get wallet summary
  Future<Either<Failure, WalletSummary>> getWallet();

  /// Get wallet transactions
  Future<Either<Failure, List<WalletTransaction>>> getWalletTransactions({
    required int page,
    required int limit,
  });
}
