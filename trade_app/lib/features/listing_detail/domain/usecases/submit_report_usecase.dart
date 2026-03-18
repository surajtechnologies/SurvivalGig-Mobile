import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/listing_detail_repository.dart';

/// Use case for submitting listing detail report
class SubmitReportUseCase {
  final ListingDetailRepository repository;

  SubmitReportUseCase({required this.repository});

  Future<Either<Failure, String>> call({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    final trimmedTargetType = targetType.trim().toUpperCase();
    final trimmedTargetId = targetId.trim();
    final trimmedReason = reason.trim();
    final trimmedDescription = description.trim();

    if (trimmedTargetType.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Target type is required',
          code: 'TARGET_TYPE_REQUIRED',
        ),
      );
    }

    if (trimmedTargetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Target id is required',
          code: 'TARGET_ID_REQUIRED',
        ),
      );
    }

    if (trimmedReason.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Reason for report is required',
          code: 'REPORT_REASON_REQUIRED',
        ),
      );
    }

    if (trimmedDescription.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Detailed description is required',
          code: 'REPORT_DESCRIPTION_REQUIRED',
        ),
      );
    }

    return repository.submitReport(
      targetType: trimmedTargetType,
      targetId: trimmedTargetId,
      reason: trimmedReason,
      description: trimmedDescription,
    );
  }
}
