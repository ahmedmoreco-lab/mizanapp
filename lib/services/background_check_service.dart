import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import 'local_notification_service.dart';

/// Pure decision for an Elder's own self-reminder evaluation.
enum ElderSelfDecision { none, selfReminder }

/// Possible decisions for a Contact viewing one of their linked Elders.
enum ContactDecision { sos, inactivity }

/// Pure + side-effecting logic for client-side local notifications.
///
/// Shared between three callers:
///   1. The workmanager periodic background task (every ~15 min, OS-limited).
///   2. The safety monitor's foreground service (every ~60 sec while running).
///   3. The foreground stream listeners in providers (instant while app open).
class BackgroundCheckService {
  BackgroundCheckService._();

  // De-dup windows — don't repeat the same alert during these.
  static const Duration sosDedupWindow = Duration(minutes: 15);
  static const Duration inactivityDedupWindow = Duration(hours: 1);
  static const Duration selfReminderDedupWindow = Duration(hours: 1);

  // Activity-gap threshold default for the elder self-reminder when the user
  // doc doesn't set inactivityThresholdHours.
  static const int defaultElderActivityThresholdHours = 12;

  // ───────────────────────── PURE EVALUATION ────────────────────────────

  /// Returns whether the Elder themselves should be nudged with a
  /// "Are you okay?" notification, based on their status doc.
  static ElderSelfDecision evaluateElderSelf({
    required DateTime now,
    required Map<String, dynamic> user,
    required Map<String, dynamic> status,
  }) {
    final monitoringEnabled = status['monitoringEnabled'] as bool? ?? false;
    if (!monitoringEnabled) return ElderSelfDecision.none;

    final lastActivity = (status['lastActivityAt'] as Timestamp?)?.toDate();
    if (lastActivity == null) return ElderSelfDecision.none;

    final thresholdHours = (user['inactivityThresholdHours'] as num?)?.toInt() ??
        defaultElderActivityThresholdHours;
    final gap = now.difference(lastActivity);
    if (gap.inHours < thresholdHours) return ElderSelfDecision.none;

    final promptSent = status['activityCheckPromptSent'] as bool? ?? false;
    if (promptSent) {
      final lastPromptAt =
          (status['activityPromptSentAt'] as Timestamp?)?.toDate();
      if (lastPromptAt != null &&
          now.difference(lastPromptAt) < selfReminderDedupWindow) {
        return ElderSelfDecision.none;
      }
    }
    return ElderSelfDecision.selfReminder;
  }

  /// Returns the set of alerts a Contact should see for one linked Elder.
  static Set<ContactDecision> evaluateContactView({
    required DateTime now,
    required Map<String, dynamic> elder,
    required Map<String, dynamic> status,
  }) {
    final out = <ContactDecision>{};

    final sosActive = status['sosActive'] as bool? ?? false;
    if (sosActive) {
      final lastSos = (status['lastSosNotifiedAt'] as Timestamp?)?.toDate();
      if (lastSos == null || now.difference(lastSos) >= sosDedupWindow) {
        out.add(ContactDecision.sos);
      }
    }

    final lastCheckIn = (elder['lastCheckIn'] as Timestamp?)?.toDate();
    final thresholdHours =
        (elder['inactivityThresholdHours'] as num?)?.toInt() ?? 24;
    if (lastCheckIn != null &&
        now.difference(lastCheckIn).inHours >= thresholdHours) {
      final lastInact =
          (status['lastInactivityNotifiedAt'] as Timestamp?)?.toDate();
      if (lastInact == null ||
          now.difference(lastInact) >= inactivityDedupWindow) {
        out.add(ContactDecision.inactivity);
      }
    }

    return out;
  }

  // ───────────────────── FIRESTORE + NOTIFICATION ────────────────────────

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Reads Firestore for [uid], decides what to notify, fires local
  /// notifications, and updates the de-dup timestamps. Safe to call from
  /// any isolate as long as Firebase is initialized in that isolate.
  static Future<void> runForCurrentUser(String uid) async {
    try {
      final userSnap = await _db.collection('users').doc(uid).get();
      if (!userSnap.exists) return;
      final userData = userSnap.data() ?? <String, dynamic>{};
      final role = userData['role']?.toString().toLowerCase();

      if (role == 'elder') {
        await _runElderCheck(uid, userData);
      } else if (role == 'contact') {
        await _runContactCheck(uid);
      }
    } catch (e) {
      debugPrint('BackgroundCheckService.runForCurrentUser failed: $e');
    }
  }

  static Future<void> _runElderCheck(
    String elderId,
    Map<String, dynamic> userData,
  ) async {
    final statusRef = _db
        .collection('users')
        .doc(elderId)
        .collection('status')
        .doc('current');
    final statusSnap = await statusRef.get();
    if (!statusSnap.exists) return;
    final status = statusSnap.data() ?? <String, dynamic>{};

    final decision = evaluateElderSelf(
      now: DateTime.now(),
      user: userData,
      status: status,
    );
    if (decision == ElderSelfDecision.selfReminder) {
      await LocalNotificationsHelper.showSelfReminder();
      await statusRef.set({
        'activityCheckPromptSent': true,
        'activityPromptSentAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> _runContactCheck(String contactUid) async {
    final eldersSnap = await _db
        .collection('users')
        .where('trustedContacts', arrayContains: contactUid)
        .get();

    for (final elderDoc in eldersSnap.docs) {
      try {
        await _runContactCheckForElder(elderDoc);
      } catch (e) {
        debugPrint('Contact check failed for ${elderDoc.id}: $e');
      }
    }
  }

  static Future<void> _runContactCheckForElder(
    QueryDocumentSnapshot<Map<String, dynamic>> elderDoc,
  ) async {
    final elderId = elderDoc.id;
    final elderData = elderDoc.data();
    final elderName = (elderData['name'] as String?) ??
        (elderData['email'] as String?) ??
        'Your elder';
    final thresholdHours =
        (elderData['inactivityThresholdHours'] as num?)?.toInt() ?? 24;

    final statusRef = _db
        .collection('users')
        .doc(elderId)
        .collection('status')
        .doc('current');
    final statusSnap = await statusRef.get();
    if (!statusSnap.exists) return;
    final status = statusSnap.data() ?? <String, dynamic>{};

    final decisions = evaluateContactView(
      now: DateTime.now(),
      elder: elderData,
      status: status,
    );

    if (decisions.contains(ContactDecision.sos)) {
      await LocalNotificationsHelper.showSos(elderName: elderName);
      await statusRef.set(
        {'lastSosNotifiedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    if (decisions.contains(ContactDecision.inactivity)) {
      await LocalNotificationsHelper.showInactivity(
        elderName: elderName,
        hours: thresholdHours,
      );
      await statusRef.set(
        {'lastInactivityNotifiedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
  }
}

// ─────────────────── workmanager top-level callback ──────────────────────
//
// MUST be top-level (or static) and annotated with vm:entry-point so the
// AOT compiler keeps it. workmanager spawns a fresh isolate for each task,
// so Firebase must be re-initialized here.

@pragma('vm:entry-point')
void backgroundCheckCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await LocalNotificationsHelper.ensureReady();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('workmanager: no signed-in user, skipping check.');
        return true;
      }
      await BackgroundCheckService.runForCurrentUser(user.uid);
      return true;
    } catch (e) {
      debugPrint('workmanager callback failed: $e');
      return true; // swallow — don't retry storms
    }
  });
}

/// Helpers to register / cancel the workmanager periodic task.
class BackgroundCheckScheduler {
  BackgroundCheckScheduler._();

  static const String periodicTaskUniqueName = 'soulping_periodic_check';
  static const String periodicTaskName = 'soulping_check';

  /// Initializes the workmanager. Call once in main() before runApp.
  static Future<void> initWorkmanager() async {
    try {
      await Workmanager().initialize(
        backgroundCheckCallbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    } catch (e) {
      debugPrint('Workmanager init failed: $e');
    }
  }

  /// Registers the 15-minute periodic check (idempotent — `keep` policy).
  static Future<void> registerPeriodicTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        periodicTaskUniqueName,
        periodicTaskName,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('Workmanager register failed: $e');
    }
  }

  static Future<void> cancelPeriodicTask() async {
    try {
      await Workmanager().cancelByUniqueName(periodicTaskUniqueName);
    } catch (e) {
      debugPrint('Workmanager cancel failed: $e');
    }
  }
}
