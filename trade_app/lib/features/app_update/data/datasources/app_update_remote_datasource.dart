import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/update_check_result.dart';
import '../models/update_check_result_model.dart';

/// Remote datasource for fetching update config from Firebase Remote Config
abstract class AppUpdateRemoteDataSource {
  /// Initialize Firebase Remote Config settings and fetch values
  Future<void> initialize();

  /// Check for update by comparing app version against remote config values
  Future<UpdateCheckResultModel> checkForUpdate({required bool isSnoozed});
}

class AppUpdateRemoteDataSourceImpl implements AppUpdateRemoteDataSource {
  final FirebaseRemoteConfig remoteConfig;

  AppUpdateRemoteDataSourceImpl({required this.remoteConfig});

  @override
  Future<void> initialize() async {
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode
                  ? Duration.zero
                  : const Duration(hours: 1),
        ),
      );

      await remoteConfig.setDefaults({
        'force_update_version': '1.0.0',
        'latest_version': '1.0.0',
        'update_message': 'A new version is available.',
        'android_store_url': '',
        'ios_store_url': '',
        'snooze_duration_hours': 24,
      });

      await remoteConfig.fetchAndActivate();
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to initialize remote config: $e',
        code: 'REMOTE_CONFIG_INIT_FAILED',
      );
    }
  }

  @override
  Future<UpdateCheckResultModel> checkForUpdate({
    required bool isSnoozed,
  }) async {
    try {
      await remoteConfig.fetchAndActivate();

      final forceUpdateVersion = remoteConfig.getString(
        'force_update_version',
      );
      final latestVersion = remoteConfig.getString('latest_version');
      final updateMessage = remoteConfig.getString('update_message');
      final androidStoreUrl = remoteConfig.getString('android_store_url');
      final iosStoreUrl = remoteConfig.getString('ios_store_url');

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final storeUrl = Platform.isAndroid ? androidStoreUrl : iosStoreUrl;

      final updateType = _determineUpdateType(
        currentVersion: currentVersion,
        forceUpdateVersion: forceUpdateVersion,
        latestVersion: latestVersion,
      );

      return UpdateCheckResultModel(
        type: updateType,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        updateMessage: updateMessage,
        storeUrl: storeUrl,
        isSnoozed: isSnoozed,
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to check for update: $e',
        code: 'UPDATE_CHECK_FAILED',
      );
    }
  }

  UpdateType _determineUpdateType({
    required String currentVersion,
    required String forceUpdateVersion,
    required String latestVersion,
  }) {
    if (_isVersionLower(currentVersion, forceUpdateVersion)) {
      return UpdateType.forced;
    }

    if (_isVersionLower(currentVersion, latestVersion)) {
      return UpdateType.optional;
    }

    return UpdateType.none;
  }

  bool _isVersionLower(String current, String target) {
    final currentParts = _parseVersion(current);
    final targetParts = _parseVersion(target);

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < targetParts[i]) return true;
      if (currentParts[i] > targetParts[i]) return false;
    }

    return false;
  }

  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return List.generate(3, (i) {
      if (i < parts.length) {
        return int.tryParse(parts[i]) ?? 0;
      }
      return 0;
    });
  }
}
