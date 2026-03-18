import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trade_message.dart';
import '../repositories/trades_repository.dart';

/// Use case for fetching trade messages
class GetTradeMessagesUseCase {
  final TradesRepository repository;

  GetTradeMessagesUseCase({required this.repository});

  Future<Either<Failure, List<TradeMessage>>> call({
    required String tradeId,
    int? page,
    int? limit,
    DateTime? since,
  }) async {
    return repository.getTradeMessages(
      tradeId: tradeId,
      page: page,
      limit: limit,
      since: since,
    );
  }
}
