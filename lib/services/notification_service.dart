import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Handles all push notification setup and foreground display.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'soulping_alerts';
  static const _channelName = 'SoulPing Safety Alerts';

  Future<void> initialize() async {
    // --- 1. Request Permissions ---
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
    } else {
      debugPrint('⚠️ Notification permission denied');
    }

    // --- 2. Setup local notifications (for foreground display) ---
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: darwinSettings),
    );

    // --- 3. Create Android Notification Channel (required Android 8+) ---
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Safety alerts from SoulPing Care',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

    // --- 4. Handle foreground FCM messages and show local notification ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message: ${message.messageId}');
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'SoulPing Alert',
          body: notification.body ?? '',
        );
      }
    });

    // --- 5. Handle notification tap when app is in background ---
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification tapped from background: ${message.messageId}');
      // Future: navigate to specific screen based on message data
    });
  }

  /// Shows a local notification even while the app is in the foreground.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Call this to manually display a local safety alert (e.g., when app opens and elder is overdue).
  Future<void> showSafetyAlert({required String elderName}) async {
    await _showLocalNotification(
      title: '⚠️ Safety Check Needed',
      body: '$elderName has not checked in for over 24 hours.',
    );
  }
}
