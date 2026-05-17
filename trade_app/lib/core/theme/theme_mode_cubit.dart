import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeCubit extends Cubit<ThemeMode> {
  static const String _storageKey = 'theme_mode';

  final FlutterSecureStorage _storage;

  ThemeModeCubit({required FlutterSecureStorage storage})
    : _storage = storage,
      super(ThemeMode.system);

  Future<void> loadThemeMode() async {
    final storedValue = await _storage.read(key: _storageKey);
    emit(_themeModeFromValue(storedValue));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _storage.write(key: _storageKey, value: mode.name);
  }

  ThemeMode _themeModeFromValue(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
