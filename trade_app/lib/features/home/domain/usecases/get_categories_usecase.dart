import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/category.dart';
import '../repositories/home_repository.dart';

/// Get categories usecase
/// Handles fetching all categories
class GetCategoriesUseCase {
  final HomeRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<Either<Failure, List<Category>>> call() async {
    return await repository.getCategories();
  }
}
