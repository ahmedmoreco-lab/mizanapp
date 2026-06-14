import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Static helper for showing local notifications from ANY isolate
/// (main, workmanager callback, or the foreground service).
///
/// The plugin instance and channel registration are isolate-scoped, so
/// every isolate that wants to show a notification must call [ensureReady]
/// first. The check is idempotent.
class LocalNotificationsHelper {
  LocalNotificationsHelper._();

  static const String channelId = 'soulping_alerts';
  static const String channelName = 'SoulPing Safety Alerts';
  static const String channelDescription = 'Safety alerts from SoulPing Care';

  // Distinct, stable IDs so the same kind of alert never stacks.
  static const int sosNotificationId = 1001;
  static const int inactivityNotificationId = 1002;
  static const int selfReminderNotificationId = 1003;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;

  /// Initializes the plugin and creates the Android channel.
  /// Safe to call multiple times — does nothing after the first success.
  static Future<void> ensureReady() async {
    if (_ready) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: channelDescription,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
      _ready = true;
    } catch (e) {
      debugPrint('LocalNotificationsHelper.ensureReady failed: $e');
    }
  }

  static Future<void> showSos({required String elderName}) async {
    await ensureReady();
    final l = await _strings();
    await _plugin.show(
      sosNotificationId,
      l.sosTitle,
      l.sosBody(elderName),
      _details(importance: Importance.max, priority: Priority.max),
    );
  }

  static Future<void> showInactivity({
    required String elderName,
    required int hours,
  }) async {
    await ensureReady();
    final l = await _strings();
    await _plugin.show(
      inactivityNotificationId,
      l.inactivityTitle,
      l.inactivityBody(elderName, hours),
      _details(importance: Importance.high, priority: Priority.high),
    );
  }

  static Future<void> showSelfReminder() async {
    await ensureReady();
    final l = await _strings();
    await _plugin.show(
      selfReminderNotificationId,
      l.selfReminderTitle,
      l.selfReminderBody,
      _details(
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
  }

  /// Generic local notification used by [NotificationService] when an FCM
  /// foreground message arrives. Reuses this helper's channel so there is
  /// only one channel definition app-wide. Uses a per-call unique ID so
  /// FCM-driven alerts do not collide with the semantic ones above.
  static Future<void> showFromFcm({
    required String title,
    required String body,
  }) async {
    await ensureReady();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _details(importance: Importance.max, priority: Priority.high),
    );
  }

  /// Reads the saved locale code from SharedPreferences (matches the same
  /// key used by [LocaleProvider]) and returns localized notification
  /// strings. Defaults to English on any failure.
  static Future<_NotifStrings> _strings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale') ?? 'en';
      return code == 'ar' ? _arabicStrings : _englishStrings;
    } catch (_) {
      return _englishStrings;
    }
  }

  static NotificationDetails _details({
    required Importance importance,
    required Priority priority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

class _NotifStrings {
  final String sosTitle;
  final String Function(String elderName) sosBody;
  final String inactivityTitle;
  final String Function(String elderName, int hours) inactivityBody;
  final String selfReminderTitle;
  final String selfReminderBody;

  const _NotifStrings({
    required this.sosTitle,
    required this.sosBody,
    required this.inactivityTitle,
    required this.inactivityBody,
    required this.selfReminderTitle,
    required this.selfReminderBody,
  });
}

final _NotifStrings _englishStrings = _NotifStrings(
  sosTitle: '🚨 EMERGENCY',
  sosBody: (name) =>
      '$name has pressed the SOS button. Please check on them now.',
  inactivityTitle: '⚠️ No check-in',
  inactivityBody: (name, hours) =>
      '$name has not checked in for $hours hours. Please check on them.',
  selfReminderTitle: '👋 Are you okay?',
  selfReminderBody:
      "We noticed no activity for a while. Please open SoulPing Care and tap I'm OK.",
);

final _NotifStrings _arabicStrings = _NotifStrings(
  sosTitle: '🚨 طوارئ',
  sosBody: (name) => 'ضغط $name زر الاستغاثة. يرجى الاطمئنان عليه الآن.',
  inactivityTitle: '⚠️ لم يسجل الحضور',
  inactivityBody: (name, hours) =>
      'لم يسجل $name حضوره منذ $hours ساعة. يرجى الاطمئنان عليه.',
  selfReminderTitle: '👋 هل أنت بخير؟',
  selfReminderBody:
      'لاحظنا عدم وجود نشاط لفترة. يرجى فتح SoulPing Care والضغط على "بخير".',
);
