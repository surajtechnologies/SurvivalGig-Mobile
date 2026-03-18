import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../config/env/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/cached_location_model.dart';

/// Home local datasource for location persistence.
abstract class HomeLocalDataSource {
  Future<CachedLocationModel?> getSavedLocation();

  Future<void> saveLocation(CachedLocationModel location);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final FlutterSecureStorage storage;

  HomeLocalDataSourceImpl({required this.storage});

  @override
  Future<CachedLocationModel?> getSavedLocation() async {
    try {
      final city = await storage.read(key: AppConfig.homeLocationCityKey);
      final pincode = await storage.read(key: AppConfig.homeLocationPincodeKey);

      if (city == null || pincode == null || city.isEmpty || pincode.isEmpty) {
        return null;
      }

      return CachedLocationModel(city: city, pincode: pincode);
    } catch (_) {
      throw const CacheException(
        message: 'Failed to read saved location',
        code: 'LOCATION_CACHE_READ_FAILED',
      );
    }
  }

  @override
  Future<void> saveLocation(CachedLocationModel location) async {
    try {
      await storage.write(
        key: AppConfig.homeLocationCityKey,
        value: location.city,
      );
      await storage.write(
        key: AppConfig.homeLocationPincodeKey,
        value: location.pincode,
      );
    } catch (_) {
      throw const CacheException(
        message: 'Failed to save location',
        code: 'LOCATION_CACHE_WRITE_FAILED',
      );
    }
  }
}
