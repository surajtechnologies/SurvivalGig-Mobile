import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trades_repository.dart';

/// Use case for rejecting trade
class RejectTradeUseCase {
  final TradesRepository repository;

  RejectTradeUseCase({required this.repository});

  Future<Either<Failure, bool>> call({required String tradeId}) async {
    return repository.rejectTrade(tradeId: tradeId);
  }
}
