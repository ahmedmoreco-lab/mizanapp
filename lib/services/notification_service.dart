import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_service.dart';

/// FCM lifecycle wrapper.
///
/// The local-notification plugin + channel + display is owned by
/// [LocalNotificationsHelper]. This service is intentionally narrow:
///   - request the FCM permission
///   - ensure the shared local-notification channel exists
///   - forward foreground FCM messages to the helper for display
///   - hook FCM tap handling (background open)
///
/// While the project is on the free Spark plan, the FCM listeners below do
/// not fire — Cloud Functions can't push messages without Blaze. They are
/// kept ready so a future Blaze upgrade lights them up automatically.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
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

    // Single source of truth for the local-notification channel + plugin.
    await LocalNotificationsHelper.ensureReady();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground FCM: ${message.messageId}');
      final notification = message.notification;
      if (notification == null) return;
      LocalNotificationsHelper.showFromFcm(
        title: notification.title ?? 'Mizan Alert',
        body: notification.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 FCM tap from background: ${message.messageId}');
      // Future: navigate to a specific screen based on message data.
    });
  }
}
