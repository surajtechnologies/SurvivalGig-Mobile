import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trade_detail.dart';
import '../repositories/trades_repository.dart';

/// Use case for fetching trade detail
class GetTradeDetailUseCase {
  final TradesRepository repository;

  GetTradeDetailUseCase({required this.repository});

  Future<Either<Failure, TradeDetail>> call({required String tradeId}) async {
    return repository.getTradeDetail(tradeId: tradeId);
  }
}
