/// API endpoints for BarterX Trade System API
class ApiEndpoints {
  // Base URLs
  static const String productionBaseUrl =
      'https://barterx-backend-u4wpmwmtkq-uc.a.run.app/api';
  static const String cloudRunBaseUrl =
      'https://barterx-backend-u4wpmwmtkq-uc.a.run.app/api';
  static const String stagingBaseUrl =
      'https://barterx-backend-u4wpmwmtkq-uc.a.run.app/api';
  static const String developmentBaseUrl =
      'https://barterx-backend-u4wpmwmtkq-uc.a.run.app/api';

  // Current base URL - change this based on environment
  // Set to Cloud Run deployment by default (provided)
  static const String baseUrl = cloudRunBaseUrl;

  // Authentication endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String mobileGoogle = '/auth/mobile/google';
  static const String mobileFacebook = '/auth/mobile/facebook';

  // User endpoints
  static const String currentUser = '/users/me';
  static String getUserById(String id) => '/users/$id';
  static const String updateProfile = '/users/me';
  static const String uploadIdDocument = '/users/me/id-document';
  static const String wallet = '/users/me/wallet';
  static const String walletTransactions = '/users/me/wallet/transactions';
  static const String deviceToken = '/users/me/device-token';

  // Listings endpoints
  static const String listings = '/listings';
  static String getListingById(String id) => '/listings/$id';
  static String updateListing(String id) => '/listings/$id';
  static String deleteListing(String id) => '/listings/$id';
  static const String myListings = '/listings/me/listings';
  static String listingTrades(String listingId) => '/listings/$listingId/trades';

  // Trades endpoints
  static const String trades = '/trades';
  static String getTradeById(String id) => '/trades/$id';
  static String buyNow(String listingId) => '/trades/buy-now/$listingId';
  static String counterOffer(String id) => '/trades/$id/counter';
  static String acceptTrade(String id) => '/trades/$id/accept';
  static String rejectTrade(String id) => '/trades/$id/reject';
  static String cancelTrade(String id) => '/trades/$id/cancel';
  static String confirmTrade(String id) => '/trades/$id/confirm';
  static String reviewTrade(String id) => '/trades/$id/review';
  static String tradeMessages(String id) => '/trades/$id/messages';

  // Reviews endpoints
  static String getUserReviews(String userId) => '/users/$userId/reviews';

  // Categories endpoints
  static const String categories = '/categories';

  // Reports endpoints
  static const String reports = '/reports';

  // Uploads endpoints
  static const String uploads = '/uploads';
  static const String upload = '/upload';

  // Favorites endpoints
  static const String favorites = '/favorites';
  static String addToFavorites(String listingId) => '/favorites/$listingId';
  static String removeFromFavorites(String listingId) =>
      '/favorites/$listingId';

  // Notifications endpoints
  static const String notifications = '/notifications';
  static String markNotificationAsRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsAsRead = '/notifications/read-all';

  // Search endpoints
  static const String search = '/search';

  // External location lookup endpoint
  static String usPincodeLookup(String pincode) =>
      'https://api.zippopotam.us/us/$pincode';

  // Admin endpoints
  static const String adminUsers = '/admin/users';
  static String adminGetUser(String id) => '/admin/users/$id';
  static String adminBanUser(String id) => '/admin/users/$id/ban';
  static String adminUnbanUser(String id) => '/admin/users/$id/unban';
  static String adminVerifyUser(String id) => '/admin/users/$id/verify';
  static String adminUpdateUserRole(String id) => '/admin/users/$id/role';
  static const String adminTrades = '/admin/trades';
  static String adminGetTrade(String id) => '/admin/trades/$id';
  static String adminResolveTrade(String id) => '/admin/trades/$id/resolve';
  static const String adminListings = '/admin/listings';
  static String adminDeleteListing(String id) => '/admin/listings/$id';
  static const String adminReports = '/admin/reports';
  static String adminUpdateReport(String id) => '/admin/reports/$id';
  static const String adminCategories = '/admin/categories';
  static String adminUpdateCategory(String id) => '/admin/categories/$id';
  static String adminDeleteCategory(String id) => '/admin/categories/$id';
  static const String adminAnalyticsOverview = '/admin/analytics/overview';
  static const String adminAnalyticsTrades = '/admin/analytics/trades';
  static const String adminAnalyticsUsers = '/admin/analytics/users';
}
