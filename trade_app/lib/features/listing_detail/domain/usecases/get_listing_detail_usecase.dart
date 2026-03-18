import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/listing.dart';
import '../repositories/listing_detail_repository.dart';

/// Use case for getting listing details
class GetListingDetailUseCase {
  final ListingDetailRepository repository;

  GetListingDetailUseCase({required this.repository});

  /// Execute the get listing detail use case
  ///
  /// [id] - The listing ID
  ///
  /// Returns [Listing] on success or [Failure] on error
  Future<Either<Failure, Listing>> call({required String id}) async {
    // Validation
    if (id.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Listing ID is required',
          code: 'EMPTY_ID',
        ),
      );
    }

    return await repository.getListingById(id: id);
  }
}
