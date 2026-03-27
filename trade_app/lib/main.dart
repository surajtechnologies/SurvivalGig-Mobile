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
import 'package:trade_app/features/startup_screen/presentation/screens/startup_screen.dart';
import 'package:trade_app/shared/widgets/loading_overlay.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    'FCM onBackgroundMessage: id=${message.messageId} data=${message.data} '
    'notificationTitle=${message.notification?.title}',
  );
}

Future<void> _initializeIosFcmTokenFlow() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final isAuthorized =
      settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
  if (!isAuthorized) {
    return;
  }

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  final token = await FirebaseMessaging.instance.getToken();
  print('iOS FCM Token: $token');
  print("APNs Token: $apnsToken");

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print('Refreshed Token: $newToken');
  });
}

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final shouldEnableFirebase = _isFirebaseSupportedPlatform();

      if (shouldEnableFirebase) {
        await Firebase.initializeApp();
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

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

      // Load user session from secure storage
      await sl<UserSession>().loadUser();

      if (shouldEnableFirebase) {
        await FirebaseAnalytics.instance.logAppOpen();

        await FcmNotifications.initializeLocalNotifications();
        FcmNotifications.attachDebugListeners();

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await _initializeIosFcmTokenFlow();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userSession = sl<UserSession>();

    return BlocProvider<LoadingCubit>(
      create: (context) => sl<LoadingCubit>(),
      child: MaterialApp(
        title: 'SurvivalGig',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return LoadingOverlay(child: child ?? const SizedBox.shrink());
        },
        // Determine root screen based on first launch and login status:
        // - First launch: StartupScreen
        // - Subsequent launches: HomeScreen if logged in, LoginLandingScreen if not
        home: _getHomeScreen(userSession),
      ),
    );
  }

  Widget _getHomeScreen(UserSession userSession) {
    if (userSession.isFirstLaunch) {
      return const StartupScreen();
    } else if (userSession.isLoggedIn) {
      return const HomeScreen();
    } else {
      return const LoginLandingScreen();
    }
  }
}
