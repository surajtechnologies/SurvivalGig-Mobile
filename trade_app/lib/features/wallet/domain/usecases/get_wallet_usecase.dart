import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_summary.dart';
import '../repositories/wallet_repository.dart';

/// Use case for fetching wallet summary
class GetWalletUseCase {
  final WalletRepository repository;

  GetWalletUseCase({required this.repository});

  Future<Either<Failure, WalletSummary>> call() {
    return repository.getWallet();
  }
}
