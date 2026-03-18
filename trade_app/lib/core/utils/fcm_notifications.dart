import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmNotifications {
  static const String androidChannelId = 'high_importance_channel';
  static const String androidChannelName = 'High Importance Notifications';
  static const String androidChannelDescription =
      'Used for important push notifications.';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(initSettings);

    final android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }

    const channel = AndroidNotificationChannel(
      androidChannelId,
      androidChannelName,
      description: androidChannelDescription,
      importance: Importance.high,
    );

    await android.createNotificationChannel(channel);
  }

  static Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;

    if (notification == null) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: android?.smallIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  static void attachDebugListeners() {
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint(
        'FCM onMessage: id=${message.messageId} data=${message.data} '
        'notificationTitle=${message.notification?.title}',
      );
      await showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        'FCM onMessageOpenedApp: id=${message.messageId} data=${message.data} '
        'notificationTitle=${message.notification?.title}',
      );
    });
  }
}

