import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trades_repository.dart';

/// Use case for confirming trade
class ConfirmTradeUseCase {
  final TradesRepository repository;

  ConfirmTradeUseCase({required this.repository});

  Future<Either<Failure, bool>> call({required String tradeId}) async {
    return repository.confirmTrade(tradeId: tradeId);
  }
}
