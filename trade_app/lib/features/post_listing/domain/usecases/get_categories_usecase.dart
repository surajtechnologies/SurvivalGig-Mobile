import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/category.dart';
import '../repositories/post_listing_repository.dart';

/// Get categories usecase for post listing
/// Fetches all available categories for the dropdown
class GetCategoriesUseCase {
  final PostListingRepository repository;

  GetCategoriesUseCase({required this.repository});

  Future<Either<Failure, List<Category>>> call() async {
    return await repository.getCategories();
  }
}
