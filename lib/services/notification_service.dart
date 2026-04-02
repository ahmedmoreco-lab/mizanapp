import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request permissions for notifications (especially important on iOS & Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else {
      print('User denied or has not accepted permission');
    }

    // 2. Optional: Get the token to send push notifications from a backend later
    String? token = await _messaging.getToken();
    print("FCM Token: $token");

    // 3. Listen to incoming foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a foreground message: ${message.messageId}');
      // Handle foreground notifications here if needed,
      // currently the app relies on UI-based alerts instead of local timers.
    });
  }
}
