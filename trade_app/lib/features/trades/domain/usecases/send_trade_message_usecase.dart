import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trade_message.dart';
import '../repositories/trades_repository.dart';

/// Use case for sending trade messages
class SendTradeMessageUseCase {
  final TradesRepository repository;

  SendTradeMessageUseCase({required this.repository});

  Future<Either<Failure, TradeMessage>> call({
    required String tradeId,
    required String content,
  }) async {
    return repository.sendTradeMessage(
      tradeId: tradeId,
      content: content,
    );
  }
}
