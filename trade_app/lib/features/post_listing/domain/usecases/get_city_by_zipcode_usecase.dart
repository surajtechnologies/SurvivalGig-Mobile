import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/post_listing_repository.dart';

/// Resolve city name from zipcode for post listing form
class GetCityByZipcodeUseCase {
  final PostListingRepository repository;

  GetCityByZipcodeUseCase({required this.repository});

  Future<Either<Failure, String>> call({required String zipcode}) async {
    return repository.getCityByZipcode(zipcode: zipcode);
  }
}
