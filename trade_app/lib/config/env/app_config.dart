import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration
class AppConfig {
  // API Configuration
  static const String baseUrl =
      'https://barterx-backend-u4wpmwmtkq-uc.a.run.app/api';

  // Timeout Configuration (in seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String homeLocationCityKey = 'home_location_city';
  static const String homeLocationPincodeKey = 'home_location_pincode';

  // App Configuration
  static const String appName = 'Survival Gig';
  static const String appVersion = '1.0.0';

  // Google Sign-In
  static String get googleIosClientId => dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
  static String get googleAndroidClientId => dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ?? '';
  static String get googleServerClientId => dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  // Facebook Sign-In
  static String get facebookAppId => dotenv.env['FACEBOOK_APP_ID'] ?? '';
  static String get facebookClientToken => dotenv.env['FACEBOOK_CLIENT_TOKEN'] ?? '';
}
