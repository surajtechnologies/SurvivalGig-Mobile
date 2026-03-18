import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trades_page.dart';
import '../repositories/trades_repository.dart';

/// Use case for fetching trades list
class GetTradesUseCase {
  final TradesRepository repository;

  GetTradesUseCase({required this.repository});

  Future<Either<Failure, TradesPage>> call({
    required int page,
    required int limit,
  }) async {
    return repository.getTrades(page: page, limit: limit);
  }
}
