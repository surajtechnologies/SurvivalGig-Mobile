import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/update_check_result.dart';

/// App update repository contract
abstract class AppUpdateRepository {
  /// Initialize remote config settings
  Future<Either<Failure, void>> initialize();

  /// Check for available updates from remote config
  Future<Either<Failure, UpdateCheckResult>> checkForUpdate();

  /// Launch the platform-appropriate store URL
  Future<Either<Failure, void>> openStore();

  /// Snooze the optional update for the configured duration
  Future<Either<Failure, void>> snoozeUpdate();

  /// Check if the update is currently snoozed
  Future<Either<Failure, bool>> isSnoozed();

  /// Attempt Android Play Store native in-app update
  Future<Either<Failure, void>> performNativeUpdate();
}
