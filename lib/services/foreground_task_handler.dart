import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:screen_state/screen_state.dart';

import '../firebase_options.dart';
import 'background_check_service.dart';
import 'local_notification_service.dart';
import 'monitoring_service.dart';

/// Message types sent from the background isolate to the main isolate.
class MonitoringEvent {
  static const String screenUnlock = 'screen_unlock';
  static const String charging = 'charging';
  static const String heartbeat = 'heartbeat';
}

/// Entry point for the foreground service isolate. Must be a top-level
/// function annotated with `@pragma('vm:entry-point')` so the AOT compiler
/// keeps it.
@pragma('vm:entry-point')
void monitoringForegroundEntry() {
  FlutterForegroundTask.setTaskHandler(_SoulPingMonitorHandler());
}

class _SoulPingMonitorHandler extends TaskHandler {
  final Screen _screen = Screen();
  final Battery _battery = Battery();

  StreamSubscription<ScreenStateEvent>? _screenSub;
  StreamSubscription<BatteryState>? _batterySub;
  BatteryState? _lastBatteryState;
  bool _firebaseReady = false;
  bool _checkInFlight = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Bring up Firebase + local notifications in THIS isolate so the
    // 60-second piggyback check below can read Firestore and notify.
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await LocalNotificationsHelper.ensureReady();
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Monitor: Firebase init in isolate failed: $e');
    }

    try {
      _screenSub = _screen.screenStateStream.listen((event) {
        // ACTION_USER_PRESENT — the user actually unlocked the device.
        if (event == ScreenStateEvent.SCREEN_UNLOCKED) {
          _send(MonitoringEvent.screenUnlock);
        }
      });
    } catch (e) {
      debugPrint('Monitor: screen stream unavailable: $e');
    }

    try {
      _lastBatteryState = await _battery.batteryState;
      _batterySub = _battery.onBatteryStateChanged.listen((state) {
        // We treat any transition into/out of charging as an activity event.
        if (state != _lastBatteryState &&
            (state == BatteryState.charging ||
                _lastBatteryState == BatteryState.charging ||
                state == BatteryState.full)) {
          _send(MonitoringEvent.charging);
        }
        _lastBatteryState = state;
      });
    } catch (e) {
      debugPrint('Monitor: battery stream unavailable: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat → main isolate (watchdog for the provider).
    _send(MonitoringEvent.heartbeat);

    // Piggyback the local-notification check while the service is alive.
    // This is more reliable than workmanager (~1 min vs 15 min) and uses
    // the SAME logic, so behavior is consistent across all three paths.
    if (!_firebaseReady || _checkInFlight) return;
    _checkInFlight = true;
    _runPiggybackCheck().whenComplete(() => _checkInFlight = false);
  }

  Future<void> _runPiggybackCheck() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await BackgroundCheckService.runForCurrentUser(user.uid);
    } catch (e) {
      debugPrint('Monitor: piggyback check failed: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _screenSub?.cancel();
    await _batterySub?.cancel();
  }

  @override
  void onReceiveData(Object data) {
    // Reserved for future commands from the UI (e.g. force a sync).
  }

  void _send(String type) {
    try {
      FlutterForegroundTask.sendDataToMain({
        'type': type,
        'at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Monitor: sendDataToMain failed: $e');
    }
  }
}

/// Maps a [MonitoringEvent] type string to the [ActivityType] persisted
/// in Firestore. Heartbeats return null (not recorded as activity).
String? activityTypeForEvent(String eventType) {
  switch (eventType) {
    case MonitoringEvent.screenUnlock:
      return ActivityType.screenUnlock;
    case MonitoringEvent.charging:
      return ActivityType.charging;
    default:
      return null;
  }
}
