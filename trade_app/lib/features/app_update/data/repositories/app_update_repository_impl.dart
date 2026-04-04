import 'package:dartz/dartz.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/update_check_result.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_local_datasource.dart';
import '../datasources/app_update_remote_datasource.dart';
import '../datasources/play_store_update_datasource.dart';

/// App update repository implementation
class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateRemoteDataSource remoteDataSource;
  final AppUpdateLocalDataSource localDataSource;
  final PlayStoreUpdateDataSource playStoreUpdateDataSource;
  final FirebaseRemoteConfig remoteConfig;

  AppUpdateRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.playStoreUpdateDataSource,
    required this.remoteConfig,
  });

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      await remoteDataSource.initialize();

      final snoozeDuration = remoteConfig.getInt('snooze_duration_hours');
      localDataSource.setSnoozeDurationHours(
        snoozeDuration > 0 ? snoozeDuration : 24,
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          message: 'Failed to initialize update service',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UpdateCheckResult>> checkForUpdate() async {
    try {
      final snoozed = await localDataSource.isSnoozed();
      final result = await remoteDataSource.checkForUpdate(isSnoozed: snoozed);

      final snoozeDuration = remoteConfig.getInt('snooze_duration_hours');
      localDataSource.setSnoozeDurationHours(
        snoozeDuration > 0 ? snoozeDuration : 24,
      );

      return Right(result.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          message: 'Failed to check for update',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> openStore() async {
    try {
      final result = await remoteDataSource.checkForUpdate(isSnoozed: false);
      final storeUrl = result.storeUrl;

      if (storeUrl.isEmpty) {
        return const Left(
          CacheFailure(
            message: 'Store URL is not configured',
            code: 'STORE_URL_MISSING',
          ),
        );
      }

      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return const Right(null);
      }

      return const Left(
        CacheFailure(
          message: 'Could not open store URL',
          code: 'STORE_URL_LAUNCH_FAILED',
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          message: 'Failed to open store',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> snoozeUpdate() async {
    try {
      final snoozeDuration = localDataSource.getSnoozeDurationHours();
      await localDataSource.saveSnooze(snoozeDurationHours: snoozeDuration);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          message: 'Failed to snooze update',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isSnoozed() async {
    try {
      final snoozed = await localDataSource.isSnoozed();
      return Right(snoozed);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (_) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> performNativeUpdate() async {
    try {
      await playStoreUpdateDataSource.checkAndUpdate();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          message: 'Native update failed',
          code: 'UNEXPECTED_ERROR',
        ),
      );
    }
  }
}
