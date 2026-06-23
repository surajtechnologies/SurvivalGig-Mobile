import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env/app_config.dart';
import '../../features/auth/domain/entities/user.dart';

/// User session service
/// Manages the current logged-in user state globally
/// Stores user data securely using Keychain (iOS) / EncryptedSharedPreferences (Android)
class UserSession {
  final FlutterSecureStorage _storage;

  static const String _userKey = 'current_user';
  static const String _firstLaunchKey = 'has_launched_before';
  static const String _installMarkerKey = 'local_install_marker_v1';
  static const String _appStorageIdentityKey = 'app_storage_identity_v1';
  static const String _themeModeKey = 'theme_mode';
  static const String _updateSnoozeTimestampKey = 'update_snooze_timestamp';
  static const String _updateSnoozeDurationKey = 'update_snooze_duration_hours';

  User? _currentUser;
  bool _isFirstLaunch = true;
  bool _hasAuthToken = false;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  UserSession({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Get the current logged-in user
  User? get currentUser => _currentUser;

  /// Check if user has a usable local auth session.
  bool get isLoggedIn => _hasAuthToken;

  /// Check if a non-expired access token is available locally.
  bool get hasValidAuthToken => _hasAuthToken;

  /// Check if this is the first app launch
  bool get isFirstLaunch => _isFirstLaunch;

  /// Emits when the server invalidates the current session.
  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  /// Set the current user and persist to secure storage
  Future<void> setUser(User user) async {
    _currentUser = user;
    _hasAuthToken = await _hasStoredAccessToken();
    final userJson = _userToJson(user);
    await _storage.write(key: _userKey, value: jsonEncode(userJson));
  }

  /// Clear the current user (logout)
  Future<void> clearUser() async {
    _currentUser = null;
    _hasAuthToken = false;
    await _storage.delete(key: _userKey);
  }

  /// Clear all app-local persisted state used by the Flutter client.
  Future<void> clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearPersistedLocalStorage(prefs);
  }

  /// Record local install metadata without touching auth state.
  ///
  /// App install markers and version/build changes must not clear auth. The
  /// user should be sent back to login only when the stored token is
  /// expired/missing, a 401 is received, or they explicitly log out.
  Future<bool> prepareLocalStorageForCurrentInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final currentIdentity = await _currentAppStorageIdentity();

    await prefs.setBool(_installMarkerKey, true);
    await prefs.setString(_appStorageIdentityKey, currentIdentity);

    return false;
  }

  Future<void> _clearPersistedLocalStorage(SharedPreferences prefs) async {
    _currentUser = null;
    _isFirstLaunch = false;
    _hasAuthToken = false;

    await Future.wait([
      _storage.delete(key: _userKey),
      _storage.delete(key: _firstLaunchKey),
      _storage.delete(key: _themeModeKey),
      _storage.delete(key: AppConfig.accessTokenKey),
      _storage.delete(key: AppConfig.refreshTokenKey),
      _storage.delete(key: AppConfig.homeLocationCityKey),
      _storage.delete(key: AppConfig.homeLocationPincodeKey),
    ]);

    await Future.wait([
      prefs.remove(_installMarkerKey),
      prefs.remove(_appStorageIdentityKey),
      prefs.remove(_updateSnoozeTimestampKey),
      prefs.remove(_updateSnoozeDurationKey),
    ]);
  }

  Future<String> _currentAppStorageIdentity() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.packageName}:${packageInfo.version}+${packageInfo.buildNumber}';
  }

  /// Clear the current user and notify the UI to reset to login.
  Future<void> expireSession() async {
    try {
      await clearLocalStorage();
    } catch (e, stackTrace) {
      debugPrint('Error clearing local storage during session expiry: $e');
      debugPrintStack(stackTrace: stackTrace);
      _currentUser = null;
      _isFirstLaunch = false;
      _hasAuthToken = false;
    }

    _sessionExpiredController.add(null);
  }

  /// Mark that the app has been launched (call after showing startup screen)
  Future<void> markAppLaunched() async {
    _isFirstLaunch = false;
    await _storage.write(key: _firstLaunchKey, value: 'true');
  }

  /// Load user and first launch status from secure storage (call on app startup)
  Future<void> loadUser() async {
    // Check first launch status
    final hasLaunchedBefore = await _storage.read(key: _firstLaunchKey);
    _isFirstLaunch = hasLaunchedBefore == null;

    final tokenState = await _storedAccessTokenState();
    _hasAuthToken = tokenState == _AccessTokenState.valid;
    if (tokenState != _AccessTokenState.valid) {
      await _clearAuthSessionKeys();
      return;
    }

    // Load user
    final userString = await _storage.read(key: _userKey);
    if (userString == null) {
      return;
    }

    try {
      final userJson = jsonDecode(userString) as Map<String, dynamic>;
      _currentUser = _userFromJson(userJson);
    } catch (e) {
      debugPrint('Error loading user session: $e');
      _currentUser = null;
      await _storage.delete(key: _userKey);
    }
  }

  Future<bool> _hasStoredAccessToken() async {
    final token = await _storage.read(key: AppConfig.accessTokenKey);
    return token != null && token.isNotEmpty && !isJwtExpired(token);
  }

  Future<_AccessTokenState> _storedAccessTokenState() async {
    final token = await _storage.read(key: AppConfig.accessTokenKey);
    if (token == null || token.isEmpty) return _AccessTokenState.missing;
    if (isJwtExpired(token)) return _AccessTokenState.expired;
    return _AccessTokenState.valid;
  }

  static bool isJwtExpired(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return false;

      final exp = json['exp'];
      final int? expirySeconds = switch (exp) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      };
      if (expirySeconds == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        expirySeconds * 1000,
        isUtc: true,
      );
      return !expiry.isAfter((now ?? DateTime.now()).toUtc());
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearAuthSessionKeys() async {
    _currentUser = null;
    _hasAuthToken = false;
    await _storage.delete(key: _userKey);
    await _storage.delete(key: AppConfig.accessTokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
  }

  /// Convert User to JSON map
  Map<String, dynamic> _userToJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'phone': user.phone,
      'location': user.location,
      'role': user.role,
      'isEmailVerified': user.isEmailVerified,
      'createdAt': user.createdAt?.toIso8601String(),
    };
  }

  /// Convert JSON map to User
  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      role: json['role'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

enum _AccessTokenState { missing, expired, valid }
