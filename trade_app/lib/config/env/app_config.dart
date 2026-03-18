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

  // Google Sign-In (set via --dart-define for local/private credentials)
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
