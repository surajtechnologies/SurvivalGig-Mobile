import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';

/// Local datasource for managing update snooze state
abstract class AppUpdateLocalDataSource {
  /// Save snooze timestamp and duration
  Future<void> saveSnooze({required int snoozeDurationHours});

  /// Check if the update is currently snoozed
  Future<bool> isSnoozed();

  /// Get the configured snooze duration from remote config cache
  int getSnoozeDurationHours();

  /// Set the snooze duration from remote config
  void setSnoozeDurationHours(int hours);
}

class AppUpdateLocalDataSourceImpl implements AppUpdateLocalDataSource {
  static const String _snoozeTimestampKey = 'update_snooze_timestamp';
  static const String _snoozeDurationKey = 'update_snooze_duration_hours';

  int _snoozeDurationHours = 24;

  AppUpdateLocalDataSourceImpl();

  @override
  Future<void> saveSnooze({required int snoozeDurationHours}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _snoozeTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setInt(_snoozeDurationKey, snoozeDurationHours);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to save snooze: $e',
        code: 'SNOOZE_SAVE_FAILED',
      );
    }
  }

  @override
  Future<bool> isSnoozed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_snoozeTimestampKey);
      final durationHours = prefs.getInt(_snoozeDurationKey) ?? _snoozeDurationHours;

      if (timestamp == null) return false;

      final snoozeTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final snoozeEnd = snoozeTime.add(Duration(hours: durationHours));

      return DateTime.now().isBefore(snoozeEnd);
    } on Exception {
      return false;
    }
  }

  @override
  int getSnoozeDurationHours() => _snoozeDurationHours;

  @override
  void setSnoozeDurationHours(int hours) {
    _snoozeDurationHours = hours;
  }
}
