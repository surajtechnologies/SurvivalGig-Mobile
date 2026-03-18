import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trade_detail.dart';
import '../entities/trade_message.dart';
import '../entities/trades_page.dart';

/// Trades repository interface
abstract class TradesRepository {
  /// Get trades list
  Future<Either<Failure, TradesPage>> getTrades({
    required int page,
    required int limit,
  });

  /// Get trade detail
  Future<Either<Failure, TradeDetail>> getTradeDetail({
    required String tradeId,
  });

  /// Accept trade
  Future<Either<Failure, bool>> acceptTrade({required String tradeId});

  /// Reject trade
  Future<Either<Failure, bool>> rejectTrade({required String tradeId});

  /// Confirm trade
  Future<Either<Failure, bool>> confirmTrade({required String tradeId});

  /// Submit review for a completed/accepted trade
  Future<Either<Failure, bool>> submitTradeReview({
    required String tradeId,
    required int rating,
    required String comment,
  });

  /// Get trade messages
  Future<Either<Failure, List<TradeMessage>>> getTradeMessages({
    required String tradeId,
    int? page,
    int? limit,
    DateTime? since,
  });

  /// Send trade message
  Future<Either<Failure, TradeMessage>> sendTradeMessage({
    required String tradeId,
    required String content,
  });
}
