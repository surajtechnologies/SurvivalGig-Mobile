import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:trade_app/config/di/service_locator.dart';
import 'package:trade_app/core/theme/app_theme.dart';
import 'package:trade_app/core/utils/fcm_notifications.dart';
import 'package:trade_app/core/utils/user_session.dart';
import 'package:trade_app/features/auth/presentation/screens/login_landing_screen.dart';
import 'package:trade_app/features/common/presentation/cubit/loading_cubit.dart';
import 'package:trade_app/features/home/presentation/screens/home_screen.dart';
import 'package:trade_app/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:trade_app/features/app_update/presentation/widgets/update_guard.dart';
import 'package:trade_app/features/app_update/domain/usecases/perform_native_update_usecase.dart';
import 'package:trade_app/shared/widgets/loading_overlay.dart';
import 'package:trade_app/shared/widgets/keyboard_dismiss_scope.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Apple Signin state manage
bool showAppleSignIn = false;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    'FCM onBackgroundMessage: id=${message.messageId} data=${message.data} '
    'notificationTitle=${message.notification?.title}',
  );
}

Future<void> _deleteFcmTokenIfPossible() async {
  try {
    await FirebaseMessaging.instance.deleteToken();
  } catch (e) {
    debugPrint('Unable to delete FCM token during local reset: $e');
  }
}

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final shouldEnableFirebase = _isFirebaseSupportedPlatform();

      if (shouldEnableFirebase) {
        await Firebase.initializeApp();
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );

        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;

        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }

      // Initialize dependency injection
      setupServiceLocator();

      final userSession = sl<UserSession>();
      final didResetLocalState = await userSession
          .prepareLocalStorageForCurrentInstall();

      if (shouldEnableFirebase && didResetLocalState) {
        await _deleteFcmTokenIfPossible();
      }

      // Load user session only after reinstall/version reset checks.
      await userSession.loadUser();

      if (shouldEnableFirebase) {
        await FirebaseAnalytics.instance.logAppOpen();

        await FcmNotifications.initializeLocalNotifications();
        FcmNotifications.attachDebugListeners();

        // Attempt Android native Play Store in-app update
        if (defaultTargetPlatform == TargetPlatform.android) {
          sl<PerformNativeUpdateUseCase>().call();
        }
      }

      runApp(const MyApp());
    },
    (error, stack) {
      // Best-effort: avoid throwing again if Firebase wasn't initialized.
      try {
        if (_isFirebaseSupportedPlatform()) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
      } catch (_) {
        // Ignore: nothing else we can safely do here.
      }
    },
  );
}

bool _isFirebaseSupportedPlatform() {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<void>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    _sessionExpiredSubscription = sl<UserSession>().sessionExpiredStream.listen(
      (_) => _resetToLoginRoot(),
    );
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  void _resetToLoginRoot() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginLandingScreen()),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSession = sl<UserSession>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<LoadingCubit>(create: (context) => sl<LoadingCubit>()),
        BlocProvider<AppUpdateCubit>(create: (context) => sl<AppUpdateCubit>()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'SurvivalGig',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return KeyboardDismissScope(
            child: LoadingOverlay(child: child ?? const SizedBox.shrink()),
          );
        },
        // Open authenticated routes only when both user and token are present.
        home: _getHomeScreen(userSession),
      ),
    );
  }

  Widget _getHomeScreen(UserSession userSession) {
    if (userSession.isLoggedIn) {
      return const UpdateGuard(child: HomeScreen());
    }

    return const LoginLandingScreen();
  }
}
