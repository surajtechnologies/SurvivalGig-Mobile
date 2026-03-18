import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/entities/user.dart';

/// User session service
/// Manages the current logged-in user state globally
/// Stores user data securely using Keychain (iOS) / EncryptedSharedPreferences (Android)
class UserSession {
  final FlutterSecureStorage _storage;

  static const String _userKey = 'current_user';
  static const String _firstLaunchKey = 'has_launched_before';

  User? _currentUser;
  bool _isFirstLaunch = true;

  UserSession({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Get the current logged-in user
  User? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if this is the first app launch
  bool get isFirstLaunch => _isFirstLaunch;

  /// Set the current user and persist to secure storage
  Future<void> setUser(User user) async {
    _currentUser = user;
    final userJson = _userToJson(user);
    await _storage.write(key: _userKey, value: jsonEncode(userJson));
  }

  /// Clear the current user (logout)
  Future<void> clearUser() async {
    _currentUser = null;
    await _storage.delete(key: _userKey);
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

    // Load user
    final userString = await _storage.read(key: _userKey);
    if (userString != null) {
      try {
        final userJson = jsonDecode(userString) as Map<String, dynamic>;
        _currentUser = _userFromJson(userJson);
      } catch (e) {
        debugPrint('Error loading user session: $e');
        // Invalid stored data, clear it
        await clearUser();
      }
    }
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
