import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trades_repository.dart';

/// Use case for accepting trade
class AcceptTradeUseCase {
  final TradesRepository repository;

  AcceptTradeUseCase({required this.repository});

  Future<Either<Failure, bool>> call({required String tradeId}) async {
    return repository.acceptTrade(tradeId: tradeId);
  }
}
