import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/utils/user_session.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/apple_sign_in_local_datasource.dart';
import '../../features/auth/data/datasources/facebook_sign_in_local_datasource.dart';
import '../../features/auth/data/datasources/google_sign_in_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/apple_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/facebook_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/google_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/register_device_token_usecase.dart';
import '../../features/auth/domain/usecases/upload_profile_image_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/home/data/datasources/home_local_datasource.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_categories_usecase.dart';
import '../../features/home/domain/usecases/get_listings_usecase.dart';
import '../../features/home/domain/usecases/get_saved_location_usecase.dart';
import '../../features/home/domain/usecases/update_location_from_pincode_usecase.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/listing_detail/data/datasources/listing_detail_remote_datasource.dart';
import '../../features/listing_detail/data/repositories/listing_detail_repository_impl.dart';
import '../../features/listing_detail/domain/repositories/listing_detail_repository.dart';
import '../../features/listing_detail/domain/usecases/buy_now_usecase.dart';
import '../../features/listing_detail/domain/usecases/delete_listing_usecase.dart';
import '../../features/listing_detail/domain/usecases/get_listing_detail_usecase.dart';
import '../../features/listing_detail/domain/usecases/get_listing_pending_trade_usecase.dart';
import '../../features/listing_detail/domain/usecases/get_my_listings_usecase.dart';
import '../../features/listing_detail/domain/usecases/get_user_reviews_usecase.dart';
import '../../features/listing_detail/domain/usecases/submit_report_usecase.dart';
import '../../features/listing_detail/presentation/cubit/buy_now_cubit.dart';
import '../../features/listing_detail/presentation/cubit/delete_listing_cubit.dart';
import '../../features/listing_detail/presentation/cubit/listing_detail_cubit.dart';
import '../../features/listing_detail/presentation/cubit/my_listings_cubit.dart';
import '../../features/listing_detail/presentation/cubit/submit_report_cubit.dart';
import '../../features/post_listing/data/datasources/post_listing_remote_datasource.dart';
import '../../features/post_listing/data/repositories/post_listing_repository_impl.dart';
import '../../features/post_listing/domain/repositories/post_listing_repository.dart';
import '../../features/post_listing/domain/usecases/create_listing_usecase.dart';
import '../../features/post_listing/domain/usecases/get_categories_usecase.dart'
    as post_listing;
import '../../features/post_listing/domain/usecases/get_city_by_zipcode_usecase.dart';
import '../../features/post_listing/domain/usecases/upload_images_usecase.dart';
import '../../features/post_listing/presentation/cubit/post_listing_cubit.dart';
import '../../features/make_offer/data/datasources/make_offer_remote_datasource.dart';
import '../../features/make_offer/data/repositories/make_offer_repository_impl.dart';
import '../../features/make_offer/domain/repositories/make_offer_repository.dart';
import '../../features/make_offer/domain/usecases/create_trade_offer_usecase.dart';
import '../../features/make_offer/domain/usecases/upload_item_images_usecase.dart';
import '../../features/common/presentation/cubit/loading_cubit.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/get_wallet_transactions_usecase.dart';
import '../../features/wallet/presentation/cubit/wallet_cubit.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/get_profile_reviews_usecase.dart';
import '../../features/profile/domain/usecases/reset_password_usecase.dart';
import '../../features/profile/domain/usecases/send_password_reset_email_usecase.dart';
import '../../features/profile/domain/usecases/upload_profile_image_usecase.dart'
    as profile_feature;
import '../../features/profile/domain/usecases/verify_profile_usecase.dart';
import '../../features/profile/domain/usecases/delete_account_usecase.dart';
import '../../features/profile/presentation/cubit/my_ratings_cubit.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/cubit/reset_password_cubit.dart';
import '../../features/trades/data/datasources/trades_remote_datasource.dart';
import '../../features/trades/data/repositories/trades_repository_impl.dart';
import '../../features/trades/domain/repositories/trades_repository.dart';
import '../../features/trades/domain/usecases/accept_trade_usecase.dart';
import '../../features/trades/domain/usecases/confirm_trade_usecase.dart';
import '../../features/trades/domain/usecases/get_trade_detail_usecase.dart';
import '../../features/trades/domain/usecases/get_trade_messages_usecase.dart';
import '../../features/trades/domain/usecases/get_trades_usecase.dart';
import '../../features/trades/domain/usecases/reject_trade_usecase.dart';
import '../../features/trades/domain/usecases/send_trade_message_usecase.dart';
import '../../features/trades/domain/usecases/submit_trade_review_usecase.dart';
import '../../features/trades/presentation/cubit/trade_detail_cubit.dart';
import '../../features/trades/presentation/cubit/trades_cubit.dart';
import '../../features/app_update/data/datasources/app_update_remote_datasource.dart';
import '../../features/app_update/data/datasources/app_update_local_datasource.dart';
import '../../features/app_update/data/datasources/play_store_update_datasource.dart';
import '../../features/app_update/data/repositories/app_update_repository_impl.dart';
import '../../features/app_update/domain/repositories/app_update_repository.dart';
import '../../features/app_update/domain/usecases/check_for_update_usecase.dart';
import '../../features/app_update/domain/usecases/initialize_update_usecase.dart';
import '../../features/app_update/domain/usecases/open_store_usecase.dart';
import '../../features/app_update/domain/usecases/perform_native_update_usecase.dart';
import '../../features/app_update/domain/usecases/snooze_update_usecase.dart';
import '../../features/app_update/presentation/cubit/app_update_cubit.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies using get_it
/// MUST be called before runApp()
void setupServiceLocator() {
  // Core - Register as singletons
  sl.registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance);

  sl.registerLazySingleton<FirebaseCrashlytics>(
    () => FirebaseCrashlytics.instance,
  );

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Global Loading Cubit - Singleton for app-wide loading state
  sl.registerLazySingleton<LoadingCubit>(() => LoadingCubit());

  // User Session - Singleton for global user access
  sl.registerLazySingleton<UserSession>(() => UserSession(storage: sl()));

  // Connectivity Service - Singleton for network monitoring
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  sl.registerLazySingleton<DioClient>(() {
    final dioClient = DioClient(storage: sl(), loadingCubit: sl());
    // Set user session for 401 logout handling
    dioClient.setUserSession(sl<UserSession>());
    return dioClient;
  });

  // Auth - Data Layer
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<GoogleSignInLocalDataSource>(
    () => GoogleSignInLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<FacebookSignInLocalDataSource>(
    () => FacebookSignInLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<AppleSignInLocalDataSource>(
    () => AppleSignInLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      appleSignInLocalDataSource: sl(),
      facebookSignInLocalDataSource: sl(),
      googleSignInLocalDataSource: sl(),
      dioClient: sl(),
      userSession: sl(),
    ),
  );

  // Auth - Domain Layer
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));

  sl.registerLazySingleton<GoogleSignInUseCase>(
    () => GoogleSignInUseCase(sl()),
  );

  sl.registerLazySingleton<FacebookSignInUseCase>(
    () => FacebookSignInUseCase(sl()),
  );

  sl.registerLazySingleton<AppleSignInUseCase>(
    () => AppleSignInUseCase(sl()),
  );

  sl.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(sl()));

  sl.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(sl()),
  );

  sl.registerLazySingleton<UploadProfileImageUseCase>(
    () => UploadProfileImageUseCase(sl()),
  );

  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl()));

  sl.registerLazySingleton<RegisterDeviceTokenUseCase>(
    () => RegisterDeviceTokenUseCase(sl()),
  );

  // Auth - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      loginUseCase: sl(),
      appleSignInUseCase: sl(),
      facebookSignInUseCase: sl(),
      googleSignInUseCase: sl(),
      registerUseCase: sl(),
      forgotPasswordUseCase: sl(),
      uploadProfileImageUseCase: sl(),
      registerDeviceTokenUseCase: sl(),
    ),
  );

  // Home - Data Layer
  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(storage: sl()),
  );

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Home - Domain Layer
  sl.registerLazySingleton<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(sl()),
  );

  sl.registerLazySingleton<GetListingsUseCase>(() => GetListingsUseCase(sl()));

  sl.registerLazySingleton<GetSavedLocationUseCase>(
    () => GetSavedLocationUseCase(sl()),
  );

  sl.registerLazySingleton<UpdateLocationFromPincodeUseCase>(
    () => UpdateLocationFromPincodeUseCase(sl()),
  );

  // Home - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      getCategoriesUseCase: sl(),
      getListingsUseCase: sl(),
      getSavedLocationUseCase: sl(),
      updateLocationFromPincodeUseCase: sl(),
      logoutUseCase: sl(),
      connectivityService: sl(),
    ),
  );

  // Post Listing - Data Layer
  sl.registerLazySingleton<PostListingRemoteDataSource>(
    () => PostListingRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<PostListingRepository>(
    () => PostListingRepositoryImpl(remoteDataSource: sl()),
  );

  // Post Listing - Domain Layer
  sl.registerLazySingleton<UploadImagesUseCase>(
    () => UploadImagesUseCase(repository: sl()),
  );

  sl.registerLazySingleton<CreateListingUseCase>(
    () => CreateListingUseCase(repository: sl()),
  );

  sl.registerLazySingleton<post_listing.GetCategoriesUseCase>(
    () => post_listing.GetCategoriesUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetCityByZipcodeUseCase>(
    () => GetCityByZipcodeUseCase(repository: sl()),
  );

  // Post Listing - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<PostListingCubit>(
    () => PostListingCubit(
      createListingUseCase: sl(),
      uploadImagesUseCase: sl(),
      getCategoriesUseCase: sl(),
      getCityByZipcodeUseCase: sl(),
    ),
  );

  // Listing Detail - Data Layer
  sl.registerLazySingleton<ListingDetailRemoteDataSource>(
    () => ListingDetailRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<ListingDetailRepository>(
    () => ListingDetailRepositoryImpl(remoteDataSource: sl()),
  );

  // Listing Detail - Domain Layer
  sl.registerLazySingleton<GetListingDetailUseCase>(
    () => GetListingDetailUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetListingPendingTradeUseCase>(
    () => GetListingPendingTradeUseCase(repository: sl()),
  );

  sl.registerLazySingleton<BuyNowUseCase>(
    () => BuyNowUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetMyListingsUseCase>(
    () => GetMyListingsUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetUserReviewsUseCase>(
    () => GetUserReviewsUseCase(repository: sl()),
  );

  sl.registerLazySingleton<DeleteListingUseCase>(
    () => DeleteListingUseCase(repository: sl()),
  );

  sl.registerLazySingleton<SubmitReportUseCase>(
    () => SubmitReportUseCase(repository: sl()),
  );

  // Listing Detail - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<ListingDetailCubit>(
    () => ListingDetailCubit(
      getListingDetailUseCase: sl(),
      getUserReviewsUseCase: sl(),
      getListingPendingTradeUseCase: sl(),
    ),
  );

  sl.registerFactory<BuyNowCubit>(() => BuyNowCubit(buyNowUseCase: sl()));

  sl.registerFactory<MyListingsCubit>(
    () => MyListingsCubit(getMyListingsUseCase: sl()),
  );

  sl.registerFactory<DeleteListingCubit>(
    () => DeleteListingCubit(deleteListingUseCase: sl()),
  );

  sl.registerFactory<SubmitReportCubit>(
    () => SubmitReportCubit(submitReportUseCase: sl()),
  );

  // Make Offer - Data Layer
  sl.registerLazySingleton<MakeOfferRemoteDataSource>(
    () => MakeOfferRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<MakeOfferRepository>(
    () => MakeOfferRepositoryImpl(remoteDataSource: sl()),
  );

  // Make Offer - Domain Layer
  sl.registerLazySingleton<CreateTradeOfferUseCase>(
    () => CreateTradeOfferUseCase(repository: sl()),
  );

  sl.registerLazySingleton<UploadItemImagesUseCase>(
    () => UploadItemImagesUseCase(repository: sl()),
  );

  // Wallet - Data Layer
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remoteDataSource: sl()),
  );

  // Wallet - Domain Layer
  sl.registerLazySingleton<GetWalletUseCase>(
    () => GetWalletUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetWalletTransactionsUseCase>(
    () => GetWalletTransactionsUseCase(repository: sl()),
  );

  // Wallet - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<WalletCubit>(
    () =>
        WalletCubit(getWalletUseCase: sl(), getWalletTransactionsUseCase: sl()),
  );

  // Profile - Data Layer
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Profile - Domain Layer
  sl.registerLazySingleton<GetProfileUseCase>(
    () => GetProfileUseCase(repository: sl()),
  );

  sl.registerLazySingleton<profile_feature.UploadProfileImageUseCase>(
    () => profile_feature.UploadProfileImageUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetProfileReviewsUseCase>(
    () => GetProfileReviewsUseCase(repository: sl()),
  );

  sl.registerLazySingleton<VerifyProfileUseCase>(
    () => VerifyProfileUseCase(repository: sl()),
  );

  sl.registerLazySingleton<SendPasswordResetEmailUseCase>(
    () => SendPasswordResetEmailUseCase(repository: sl()),
  );

  sl.registerLazySingleton<ResetPasswordUseCase>(
    () => ResetPasswordUseCase(repository: sl()),
  );

  sl.registerLazySingleton<DeleteAccountUseCase>(
    () => DeleteAccountUseCase(repository: sl()),
  );

  // Profile - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      getProfileUseCase: sl(),
      uploadProfileImageUseCase: sl(),
      verifyProfileUseCase: sl(),
      sendPasswordResetEmailUseCase: sl(),
      deleteAccountUseCase: sl(),
    ),
  );

  sl.registerFactory<MyRatingsCubit>(
    () => MyRatingsCubit(getProfileReviewsUseCase: sl()),
  );

  sl.registerFactory<ResetPasswordCubit>(
    () => ResetPasswordCubit(
      sendPasswordResetEmailUseCase: sl(),
      resetPasswordUseCase: sl(),
    ),
  );

  // Trades - Data Layer
  sl.registerLazySingleton<TradesRemoteDataSource>(
    () => TradesRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<TradesRepository>(
    () => TradesRepositoryImpl(remoteDataSource: sl()),
  );

  // Trades - Domain Layer
  sl.registerLazySingleton<GetTradesUseCase>(
    () => GetTradesUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetTradeDetailUseCase>(
    () => GetTradeDetailUseCase(repository: sl()),
  );

  sl.registerLazySingleton<AcceptTradeUseCase>(
    () => AcceptTradeUseCase(repository: sl()),
  );

  sl.registerLazySingleton<RejectTradeUseCase>(
    () => RejectTradeUseCase(repository: sl()),
  );

  sl.registerLazySingleton<ConfirmTradeUseCase>(
    () => ConfirmTradeUseCase(repository: sl()),
  );

  sl.registerLazySingleton<GetTradeMessagesUseCase>(
    () => GetTradeMessagesUseCase(repository: sl()),
  );

  sl.registerLazySingleton<SendTradeMessageUseCase>(
    () => SendTradeMessageUseCase(repository: sl()),
  );

  sl.registerLazySingleton<SubmitTradeReviewUseCase>(
    () => SubmitTradeReviewUseCase(repository: sl()),
  );

  // Trades - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<TradesCubit>(() => TradesCubit(getTradesUseCase: sl()));

  sl.registerFactory<TradeDetailCubit>(
    () => TradeDetailCubit(
      getTradeDetailUseCase: sl(),
      acceptTradeUseCase: sl(),
      rejectTradeUseCase: sl(),
      confirmTradeUseCase: sl(),
      getTradeMessagesUseCase: sl(),
      sendTradeMessageUseCase: sl(),
      submitTradeReviewUseCase: sl(),
    ),
  );

  // App Update - Core
  sl.registerLazySingleton<FirebaseRemoteConfig>(
    () => FirebaseRemoteConfig.instance,
  );

  // App Update - Data Layer
  sl.registerLazySingleton<AppUpdateRemoteDataSource>(
    () => AppUpdateRemoteDataSourceImpl(remoteConfig: sl()),
  );

  sl.registerLazySingleton<AppUpdateLocalDataSource>(
    () => AppUpdateLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<PlayStoreUpdateDataSource>(
    () => PlayStoreUpdateDataSourceImpl(),
  );

  sl.registerLazySingleton<AppUpdateRepository>(
    () => AppUpdateRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      playStoreUpdateDataSource: sl(),
      remoteConfig: sl(),
    ),
  );

  // App Update - Domain Layer
  sl.registerLazySingleton<InitializeUpdateUseCase>(
    () => InitializeUpdateUseCase(repository: sl()),
  );

  sl.registerLazySingleton<CheckForUpdateUseCase>(
    () => CheckForUpdateUseCase(repository: sl()),
  );

  sl.registerLazySingleton<OpenStoreUseCase>(
    () => OpenStoreUseCase(repository: sl()),
  );

  sl.registerLazySingleton<SnoozeUpdateUseCase>(
    () => SnoozeUpdateUseCase(repository: sl()),
  );

  sl.registerLazySingleton<PerformNativeUpdateUseCase>(
    () => PerformNativeUpdateUseCase(repository: sl()),
  );

  // App Update - Presentation Layer (Factory - new instance each time)
  sl.registerFactory<AppUpdateCubit>(
    () => AppUpdateCubit(
      initializeUpdateUseCase: sl(),
      checkForUpdateUseCase: sl(),
      openStoreUseCase: sl(),
      snoozeUpdateUseCase: sl(),
      performNativeUpdateUseCase: sl(),
    ),
  );
}
