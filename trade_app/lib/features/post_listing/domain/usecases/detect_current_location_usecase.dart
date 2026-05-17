import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/detected_location.dart';
import '../repositories/post_listing_repository.dart';

/// Use case for detecting the user's current GPS location
class DetectCurrentLocationUseCase {
  final PostListingRepository repository;

  DetectCurrentLocationUseCase({required this.repository});

  Future<Either<Failure, DetectedLocation>> call() {
    return repository.detectCurrentLocation();
  }
}
