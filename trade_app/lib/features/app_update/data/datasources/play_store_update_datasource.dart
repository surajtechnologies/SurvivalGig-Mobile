import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../../../core/errors/exceptions.dart';

/// Datasource for Android native Play Store in-app updates
abstract class PlayStoreUpdateDataSource {
  /// Check and perform native Play Store update
  Future<void> checkAndUpdate();
}

class PlayStoreUpdateDataSourceImpl implements PlayStoreUpdateDataSource {
  PlayStoreUpdateDataSourceImpl();

  @override
  Future<void> checkAndUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } on Exception catch (e) {
      debugPrint('PlayStoreUpdate: $e');
      throw CacheException(
        message: 'Play Store update failed: $e',
        code: 'PLAY_STORE_UPDATE_FAILED',
      );
    }
  }
}
