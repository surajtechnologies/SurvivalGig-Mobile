import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trade_app/core/utils/user_session.dart';
import 'package:trade_app/features/auth/domain/usecases/register_device_token_usecase.dart';

abstract class PushNotificationService {
  Stream<PushNotificationNavigationIntent> get navigationStream;

  PushNotificationNavigationIntent? takePendingNavigationIntent();

  Future<void> initialize();

  Future<void> syncTokenForAuthenticatedUser();

  Future<void> deleteToken();
}

sealed class PushNotificationNavigationIntent {
  const PushNotificationNavigationIntent();
}

class OpenTradeChatNotificationIntent extends PushNotificationNavigationIntent {
  final String tradeId;
  final String? messageId;
  final bool focusOfferSummary;

  const OpenTradeChatNotificationIntent({
    required this.tradeId,
    this.messageId,
    this.focusOfferSummary = false,
  });
}

class FcmNotifications implements PushNotificationService {
  static const String androidChannelId = 'high_importance_channel';
  static const String androidChannelName = 'High Importance Notifications';
  static const String androidChannelDescription =
      'Used for important push notifications.';
  static const Set<String> _tradeChatNotificationTypes = {
    'trade_buy_now',
    'chat_new_message',
    'trade_new_offer',
    'trade_counter_offer',
    'counter_offer',
    'trade_accepted',
    'trade_rejected',
  };

  final FirebaseMessaging? _messagingOverride;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final RegisterDeviceTokenUseCase _registerDeviceTokenUseCase;
  final UserSession _userSession;
  final StreamController<PushNotificationNavigationIntent>
  _navigationController =
      StreamController<PushNotificationNavigationIntent>.broadcast();
  PushNotificationNavigationIntent? _pendingNavigationIntent;

  Future<void>? _activeSync;
  String? _lastUploadedToken;
  String? _lastUploadedUserId;
  bool _initialized = false;
  bool _isDeletingToken = false;

  FcmNotifications({
    required RegisterDeviceTokenUseCase registerDeviceTokenUseCase,
    required UserSession userSession,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _registerDeviceTokenUseCase = registerDeviceTokenUseCase,
       _userSession = userSession,
       _messagingOverride = messaging,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  @override
  Stream<PushNotificationNavigationIntent> get navigationStream =>
      _navigationController.stream;

  @override
  PushNotificationNavigationIntent? takePendingNavigationIntent() {
    final intent = _pendingNavigationIntent;
    _pendingNavigationIntent = null;
    return intent;
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<void> initialize() async {
    if (!_isSupportedPlatform || _initialized) return;
    _initialized = true;

    try {
      await _initializeLocalNotifications();
    } catch (error, stackTrace) {
      debugPrint('Local notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await _messaging.setAutoInitEnabled(true);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Foreground notifications are displayed by the local notifications
        // plugin so Android and iOS use one consistent presentation path.
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Firebase Messaging initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    _messaging.onTokenRefresh.listen(
      _handleTokenRefresh,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM token refresh listener failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleOpenedMessage(initialMessage);
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to read the initial FCM message: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (_userSession.isLoggedIn) {
      await syncTokenForAuthenticatedUser();
    }
  }

  @override
  Future<void> syncTokenForAuthenticatedUser() {
    if (!_isSupportedPlatform || !_userSession.isLoggedIn) {
      return Future<void>.value();
    }

    final activeSync = _activeSync;
    if (activeSync != null) return activeSync;

    final sync = _syncToken();
    _activeSync = sync;
    return sync.whenComplete(() {
      if (identical(_activeSync, sync)) {
        _activeSync = null;
      }
    });
  }

  Future<void> _syncToken() async {
    try {
      final settings = await _requestPermissionIfNeeded();
      if (!_isAuthorized(settings.authorizationStatus)) {
        debugPrint(
          'Push notification permission is not authorized: '
          '${settings.authorizationStatus.name}',
        );
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _waitForApnsToken();
        if (apnsToken == null) {
          debugPrint(
            'APNs token was not available; FCM sync will retry later.',
          );
          return;
        }
      }

      final token = await _getFcmTokenWithRetry();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token was not available; sync will retry later.');
        return;
      }

      await _uploadToken(token);
    } catch (error, stackTrace) {
      debugPrint('Push notification setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<NotificationSettings> _requestPermissionIfNeeded() async {
    var settings = await _messaging.getNotificationSettings();
    final status = settings.authorizationStatus;
    final shouldRequest =
        status == AuthorizationStatus.notDetermined ||
        (defaultTargetPlatform == TargetPlatform.android &&
            status == AuthorizationStatus.denied);

    if (shouldRequest) {
      settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return settings;
  }

  bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final token = await _messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  Future<String?> _getFcmTokenWithRetry() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (error) {
        debugPrint('FCM token fetch attempt ${attempt + 1} failed: $error');
      }

      await Future<void>.delayed(Duration(seconds: attempt + 1));
    }
    return null;
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (_isDeletingToken ||
        token.isEmpty ||
        !_userSession.isLoggedIn ||
        !_isSupportedPlatform) {
      return;
    }

    try {
      final settings = await _messaging.getNotificationSettings();
      if (!_isAuthorized(settings.authorizationStatus)) return;
      await _uploadToken(token);
    } catch (error, stackTrace) {
      debugPrint('Refreshed FCM token upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _uploadToken(String token) async {
    debugPrint('FCM Token: $token');
    final userId = _userSession.currentUser?.id;
    if (userId == null || !_userSession.isLoggedIn) return;
    if (_lastUploadedToken == token && _lastUploadedUserId == userId) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    for (var attempt = 0; attempt < 3; attempt++) {
      final result = await _registerDeviceTokenUseCase(
        token: token,
        platform: platform,
      );
      final uploaded = result.fold((failure) {
        debugPrint(
          'FCM token upload attempt ${attempt + 1} failed: '
          '${failure.message}',
        );
        return false;
      }, (_) => true);

      if (uploaded) {
        _lastUploadedToken = token;
        _lastUploadedUserId = userId;
        if (kDebugMode) {
          debugPrint('FCM token uploaded successfully for $platform.');
        }
        return;
      }

      await Future<void>.delayed(Duration(seconds: attempt + 1));
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      androidChannelId,
      androidChannelName,
      description: androidChannelDescription,
      importance: Importance.high,
    );
    await android.createNotificationChannel(channel);
  }

  Future<void> _handleLocalNotificationTap(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      _emitNavigationIntentFromData(decoded);
    } catch (error, stackTrace) {
      debugPrint('Unable to read local notification payload: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('FCM onMessage: id=${message.messageId}');
    }

    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: notification.android?.smallIcon,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.messageId?.hashCode ?? notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('FCM notification opened: id=${message.messageId}');
    }
    _emitNavigationIntentFromData(message.data);
  }

  void _emitNavigationIntentFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim();
    final tradeId = _extractTradeId(data);
    final messageId = _extractMessageId(data);
    final isTradeChatPayload =
        (type != null && _tradeChatNotificationTypes.contains(type)) ||
        _containsTradeMessagesRoute(data);
    if (tradeId == null || tradeId.isEmpty || !isTradeChatPayload) {
      return;
    }

    final intent = OpenTradeChatNotificationIntent(
      tradeId: tradeId,
      messageId: messageId,
      focusOfferSummary:
          type == 'trade_new_offer' ||
          type == 'trade_counter_offer' ||
          type == 'counter_offer',
    );
    if (!_navigationController.hasListener) {
      _pendingNavigationIntent = intent;
    }
    _navigationController.add(intent);
  }

  String? _extractTradeId(Map<String, dynamic> data) {
    final directTradeId =
        _readString(data['tradeId']) ??
        _readString(data['trade_id']) ??
        _readString(data['trade']) ??
        _readString(data['id']);
    if (directTradeId != null) return directTradeId;

    for (final key in const [
      'route',
      'path',
      'url',
      'deepLink',
      'deeplink',
      'link',
      'screen',
    ]) {
      final route = _readString(data[key]);
      final tradeId = _extractTradeIdFromRoute(route);
      if (tradeId != null) return tradeId;
    }

    for (final key in const ['data', 'payload', 'params']) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        final tradeId = _extractTradeId(nested);
        if (tradeId != null) return tradeId;
      }
      if (nested is String && nested.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(nested);
          if (decoded is Map<String, dynamic>) {
            final tradeId = _extractTradeId(decoded);
            if (tradeId != null) return tradeId;
          }
        } catch (_) {
          // Ignore invalid nested JSON payloads.
        }
      }
    }

    return null;
  }

  String? _extractMessageId(Map<String, dynamic> data) {
    final directMessageId =
        _readString(data['messageId']) ??
        _readString(data['message_id']) ??
        _readString(data['chatMessageId']) ??
        _readString(data['chat_message_id']);
    if (directMessageId != null) return directMessageId;

    for (final key in const ['data', 'payload', 'params']) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        final messageId = _extractMessageId(nested);
        if (messageId != null) return messageId;
      }
      if (nested is String && nested.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(nested);
          if (decoded is Map<String, dynamic>) {
            final messageId = _extractMessageId(decoded);
            if (messageId != null) return messageId;
          }
        } catch (_) {
          // Ignore invalid nested JSON payloads.
        }
      }
    }

    return null;
  }

  String? _extractTradeIdFromRoute(String? route) {
    if (route == null) return null;
    final match = RegExp(r'/trades/([^/?#]+)/messages').firstMatch(route);
    final tradeId = match?.group(1)?.trim();
    return tradeId == null || tradeId.isEmpty ? null : tradeId;
  }

  bool _containsTradeMessagesRoute(Map<String, dynamic> data) {
    for (final key in const [
      'route',
      'path',
      'url',
      'deepLink',
      'deeplink',
      'link',
      'screen',
    ]) {
      if (_extractTradeIdFromRoute(_readString(data[key])) != null) {
        return true;
      }
    }

    for (final key in const ['data', 'payload', 'params']) {
      final nested = data[key];
      if (nested is Map<String, dynamic> &&
          _containsTradeMessagesRoute(nested)) {
        return true;
      }
      if (nested is String && nested.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(nested);
          if (decoded is Map<String, dynamic> &&
              _containsTradeMessagesRoute(decoded)) {
            return true;
          }
        } catch (_) {
          // Ignore invalid nested JSON payloads.
        }
      }
    }

    return false;
  }

  String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  @override
  Future<void> deleteToken() async {
    if (!_isSupportedPlatform) return;

    _isDeletingToken = true;
    _lastUploadedToken = null;
    _lastUploadedUserId = null;
    try {
      await _messaging.deleteToken();
    } catch (error, stackTrace) {
      debugPrint('Unable to delete FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isDeletingToken = false;
    }
  }
}
