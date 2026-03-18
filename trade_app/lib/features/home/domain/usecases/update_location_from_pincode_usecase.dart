import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/current_location.dart';
import '../repositories/home_repository.dart';

/// Resolve city from pincode and persist it for home location.
class UpdateLocationFromPincodeUseCase {
  final HomeRepository repository;

  UpdateLocationFromPincodeUseCase(this.repository);

  Future<Either<Failure, CurrentLocation>> call({
    required String pincode,
  }) async {
    final normalizedPincode = pincode.trim();

    if (!RegExp(r'^\d{5,9}$').hasMatch(normalizedPincode)) {
      return const Left(
        ValidationFailure(
          message: 'Please enter a valid 5 to 9-digit US pincode',
          code: 'INVALID_PINCODE',
        ),
      );
    }

    return repository.updateLocationFromPincode(pincode: normalizedPincode);
  }
}
