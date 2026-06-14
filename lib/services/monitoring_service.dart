import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Activity type constants written to status/current.lastActivityType.
class ActivityType {
  static const String screenUnlock = 'screen_unlock';
  static const String charging = 'charging';
  static const String manual = 'manual';
}

/// Repository for the background safety monitor.
///
/// Writes to `users/{elderId}/status/current` are debounced — a noisy stream
/// of unlock events should not produce a write per event. Default minimum gap
/// is 5 minutes (see [debounceWindow]). The debounce is held per-elder in
/// memory; on cold start the first event after launch is always written.
class MonitoringService {
  MonitoringService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Minimum gap between two activity writes for the same elder.
  static const Duration debounceWindow = Duration(minutes: 5);

  final Map<String, DateTime> _lastWriteAt = <String, DateTime>{};

  DocumentReference<Map<String, dynamic>> _statusRef(String elderId) =>
      _db.collection(AppConstants.usersCollection)
          .doc(elderId)
          .collection('status')
          .doc('current');

  /// Records an activity event for [elderId] of [type] (see [ActivityType]).
  /// Returns true if a write actually occurred, false if debounced.
  Future<bool> recordActivity(String elderId, String type) async {
    final now = DateTime.now();
    final last = _lastWriteAt[elderId];
    if (last != null && now.difference(last) < debounceWindow) {
      return false;
    }
    try {
      await _statusRef(elderId).set({
        'lastActivityAt': FieldValue.serverTimestamp(),
        'lastActivityType': type,
        'activityCheckPromptSent': false,
      }, SetOptions(merge: true));
      _lastWriteAt[elderId] = now;
      return true;
    } catch (e) {
      debugPrint('MonitoringService.recordActivity failed: $e');
      return false;
    }
  }

  /// Toggles the monitor on/off in Firestore. Cloud Function only acts on
  /// elders whose `monitoringEnabled == true`.
  Future<void> setMonitoringEnabled(String elderId, bool enabled) async {
    try {
      await _statusRef(elderId).set({
        'monitoringEnabled': enabled,
        if (enabled) 'activityCheckPromptSent': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('MonitoringService.setMonitoringEnabled failed: $e');
      rethrow;
    }
  }

  /// Reads the current monitoring state (used by the provider on startup).
  Future<bool> isMonitoringEnabled(String elderId) async {
    try {
      final snap = await _statusRef(elderId).get();
      return (snap.data()?['monitoringEnabled'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Clears the debounce cache (e.g. when monitoring is disabled). Tests
  /// can also use this to force the next event to write.
  void clearDebounce([String? elderId]) {
    if (elderId == null) {
      _lastWriteAt.clear();
    } else {
      _lastWriteAt.remove(elderId);
    }
  }
}
