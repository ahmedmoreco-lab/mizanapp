import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/foreground_task_handler.dart';
import '../services/monitoring_service.dart';

/// State + control for the Background Safety Monitor (Android only).
///
/// The provider is the bridge between the UI toggle, the foreground service
/// (running in a background isolate), and Firestore. On iOS this provider
/// is inert — [isPlatformSupported] returns false and the UI should hide
/// the toggle.
class MonitoringProvider extends ChangeNotifier with WidgetsBindingObserver {
  MonitoringProvider({MonitoringService? service})
      : _service = service ?? MonitoringService();

  final MonitoringService _service;

  bool _enabled = false;
  bool _isStarting = false;
  bool _notificationGranted = false;
  bool _ignoreBatteryOptimizations = false;
  String? _elderUid;
  String? _errorMessage;
  bool _taskCallbackRegistered = false;
  late final void Function(Object) _taskDataCallback = _handleIsolateEvent;

  bool get isEnabled => _enabled;
  bool get isStarting => _isStarting;
  bool get notificationGranted => _notificationGranted;
  bool get ignoreBatteryOptimizations => _ignoreBatteryOptimizations;
  String? get errorMessage => _errorMessage;
  bool get isPlatformSupported => !kIsWeb && Platform.isAndroid;

  /// Called from the dashboard once the elder uid is known. Pulls the
  /// persisted state from Firestore and starts listening for isolate events
  /// if the service was already running.
  Future<void> bind(String elderUid) async {
    if (!isPlatformSupported) return;
    _elderUid = elderUid;
    WidgetsBinding.instance.addObserver(this);
    await _refreshPermissions();
    _enabled = await _service.isMonitoringEnabled(elderUid);
    final running = await FlutterForegroundTask.isRunningService;
    if (running) {
      _attachReceivePort();
    }
    notifyListeners();
  }

  // ── Permissions ────────────────────────────────────────────────────────
  Future<void> _refreshPermissions() async {
    if (!isPlatformSupported) return;
    _notificationGranted = await Permission.notification.isGranted;
    _ignoreBatteryOptimizations =
        await Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<void> refreshPermissionStatus() async {
    await _refreshPermissions();
    notifyListeners();
  }

  Future<bool> _ensureNotificationPermission() async {
    final status = await Permission.notification.request();
    _notificationGranted = status.isGranted;
    return status.isGranted;
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!isPlatformSupported) return;
    final status = await Permission.ignoreBatteryOptimizations.request();
    _ignoreBatteryOptimizations = status.isGranted;
    notifyListeners();
  }

  // ── Service control ───────────────────────────────────────────────────
  Future<bool> enableMonitoring({
    required String persistentTitle,
    required String persistentBody,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!isPlatformSupported || _elderUid == null) return false;
    _errorMessage = null;
    _isStarting = true;
    notifyListeners();

    try {
      if (!await _ensureNotificationPermission()) {
        _errorMessage = 'notification_denied';
        _isStarting = false;
        notifyListeners();
        return false;
      }

      _configureForegroundTask(
        channelName: channelName,
        channelDescription: channelDescription,
      );

      final result = await FlutterForegroundTask.startService(
        serviceId: 9101,
        notificationTitle: persistentTitle,
        notificationText: persistentBody,
        callback: monitoringForegroundEntry,
      );

      if (!_isServiceStartSuccess(result)) {
        _errorMessage = 'service_start_failed';
        _isStarting = false;
        notifyListeners();
        return false;
      }

      _attachReceivePort();
      await _service.setMonitoringEnabled(_elderUid!, true);
      // First record: app open / monitor enabled = an unambiguous "alive" signal.
      await _service.recordActivity(_elderUid!, ActivityType.manual);
      _enabled = true;
      _isStarting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('enableMonitoring failed: $e');
      _errorMessage = e.toString();
      _isStarting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disableMonitoring() async {
    if (!isPlatformSupported || _elderUid == null) return;
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('stopService failed: $e');
    }
    _detachTaskCallback();
    try {
      await _service.setMonitoringEnabled(_elderUid!, false);
    } catch (_) {}
    _service.clearDebounce(_elderUid);
    _enabled = false;
    notifyListeners();
  }

  void _configureForegroundTask({
    required String channelName,
    required String channelDescription,
  }) {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'soulping_safety_monitor',
        channelName: channelName,
        channelDescription: channelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60 * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  bool _isServiceStartSuccess(Object? result) {
    // The package returns ServiceRequestResult on recent versions;
    // older versions returned bool. Accept either form.
    if (result is bool) return result;
    try {
      // ignore: avoid_dynamic_calls
      return (result as dynamic).success == true;
    } catch (_) {
      return result != null;
    }
  }

  void _attachReceivePort() {
    if (_taskCallbackRegistered) return;
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback);
    _taskCallbackRegistered = true;
  }

  void _detachTaskCallback() {
    if (!_taskCallbackRegistered) return;
    FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback);
    _taskCallbackRegistered = false;
  }

  void _handleIsolateEvent(Object data) {
    if (_elderUid == null || data is! Map) return;
    final type = data['type'];
    if (type is! String) return;
    final activity = activityTypeForEvent(type);
    if (activity == null) return; // heartbeat or unknown — skip
    _service.recordActivity(_elderUid!, activity);
  }

  // ── App lifecycle: foreground = activity ──────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled || _elderUid == null) return;
    if (state == AppLifecycleState.resumed) {
      // Debounced inside the service.
      _service.recordActivity(_elderUid!, ActivityType.manual);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachTaskCallback();
    super.dispose();
  }
}
