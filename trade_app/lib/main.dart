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
import 'package:trade_app/core/theme/app_colors.dart';
import 'package:trade_app/core/theme/app_theme.dart';
import 'package:trade_app/core/utils/fcm_notifications.dart';
import 'package:trade_app/core/utils/user_session.dart';
import 'package:trade_app/features/auth/domain/entities/user.dart';
import 'package:trade_app/features/auth/presentation/screens/login_landing_screen.dart';
import 'package:trade_app/features/common/presentation/cubit/loading_cubit.dart';
import 'package:trade_app/features/home/presentation/screens/home_screen.dart';
import 'package:trade_app/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:trade_app/features/app_update/presentation/widgets/update_guard.dart';
import 'package:trade_app/features/app_update/domain/usecases/perform_native_update_usecase.dart';
import 'package:trade_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:trade_app/shared/widgets/loading_overlay.dart';
import 'package:trade_app/shared/widgets/keyboard_dismiss_scope.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Apple Signin state manage
bool showAppleSignIn = false;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('FCM onBackgroundMessage: id=${message.messageId}');
  }
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

      // Initialize dependency injection before runApp so the app shell can render
      // while slower platform/session setup continues in the bootstrap gate.
      setupServiceLocator();

      final bootstrapFuture = _bootstrapApp(
        shouldEnableFirebase: shouldEnableFirebase,
      );

      runApp(MyApp(bootstrapFuture: bootstrapFuture));
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

Future<void> _bootstrapApp({required bool shouldEnableFirebase}) async {
  await dotenv.load(fileName: ".env");

  if (shouldEnableFirebase) {
    await Firebase.initializeApp();
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final userSession = sl<UserSession>();
  final didResetLocalState = await userSession
      .prepareLocalStorageForCurrentInstall();

  if (shouldEnableFirebase && didResetLocalState) {
    unawaited(sl<PushNotificationService>().deleteToken());
  }

  // Load user session only after reinstall/version reset checks.
  await userSession.loadUser();
  await _hydrateMissingUserSession(userSession);

  if (shouldEnableFirebase) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runPostFirstFrameStartupTasks());
    });
  }
}

Future<void> _hydrateMissingUserSession(UserSession userSession) async {
  if (userSession.currentUser != null || !userSession.hasValidAuthToken) return;

  try {
    final profile = await sl<ProfileRemoteDataSource>().getProfile();
    if (profile.id.trim().isEmpty) return;

    await userSession.setUser(
      User(id: profile.id, email: profile.email, name: profile.fullName),
    );
  } catch (error, stackTrace) {
    debugPrint('Unable to hydrate user session from stored token: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

bool _isFirebaseSupportedPlatform() {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<void> _runPostFirstFrameStartupTasks() async {
  try {
    await Future<void>.delayed(const Duration(seconds: 2));
    await FirebaseAnalytics.instance.logAppOpen();

    await sl<PushNotificationService>().initialize();

    // Attempt Android native Play Store in-app update.
    if (defaultTargetPlatform == TargetPlatform.android) {
      unawaited(sl<PerformNativeUpdateUseCase>().call());
    }
  } catch (error, stack) {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack);
    } catch (_) {
      debugPrint('Post-frame startup task failed: $error');
      debugPrintStack(stackTrace: stack);
    }
  }
}

class MyApp extends StatefulWidget {
  final Future<void> bootstrapFuture;

  const MyApp({super.key, required this.bootstrapFuture});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<void>? _sessionExpiredSubscription;
  DateTime? _lastResumeTokenSyncAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionExpiredSubscription = sl<UserSession>().sessionExpiredStream.listen(
      (_) => _resetToLoginRoot(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        !sl<UserSession>().isLoggedIn ||
        !_isFirebaseSupportedPlatform()) {
      return;
    }

    final now = DateTime.now();
    final lastSync = _lastResumeTokenSyncAt;
    if (lastSync != null && now.difference(lastSync).inMinutes < 10) {
      return;
    }
    _lastResumeTokenSyncAt = now;
    unawaited(sl<PushNotificationService>().syncTokenForAuthenticatedUser());
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
    return BlocProvider<LoadingCubit>(
      create: (context) => sl<LoadingCubit>(),
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
        // Open authenticated routes when a usable auth token is present.
        home: FutureBuilder<void>(
          future: widget.bootstrapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _BootstrapLoadingScreen();
            }
            return _getHomeScreen(sl<UserSession>());
          },
        ),
      ),
    );
  }

  Widget _getHomeScreen(UserSession userSession) {
    if (userSession.isLoggedIn) {
      return BlocProvider<AppUpdateCubit>(
        create: (context) => sl<AppUpdateCubit>(),
        child: const UpdateGuard(child: HomeScreen()),
      );
    }

    return const LoginLandingScreen();
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
