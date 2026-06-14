import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/background_check_service.dart';
import '../services/firestore_service.dart';
import '../services/local_notification_service.dart';

class ElderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool _sosActive = false;
  bool _isResolvingSOS = false;
  StreamSubscription? _statusSubscription;

  bool get isLoading => _isLoading;
  bool get sosActive => _sosActive;
  bool get isResolvingSOS => _isResolvingSOS;

  // Called from ElderHomeScreen once the elder's uid is known.
  void startListeningToStatus(String elderUid) {
    _statusSubscription?.cancel();
    _statusSubscription = _firestoreService
        .streamElderStatus(elderUid)
        .listen((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final active = data?['sosActive'] as bool? ?? false;
      if (_sosActive != active) {
        _sosActive = active;
        notifyListeners();
      }
      _maybeFireSelfReminder(elderUid, data);
    });
  }

  /// While the app is open: evaluate the elder's own activity gap and
  /// show the gentle "Are you okay?" reminder if needed. De-duplication is
  /// done via [BackgroundCheckService.evaluateElderSelf] against the
  /// `activityCheckPromptSent` / `activityPromptSentAt` fields.
  Future<void> _maybeFireSelfReminder(
    String elderUid,
    Map<String, dynamic>? statusData,
  ) async {
    if (statusData == null) return;
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(elderUid)
          .get();
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final decision = BackgroundCheckService.evaluateElderSelf(
        now: DateTime.now(),
        user: userData,
        status: statusData,
      );
      if (decision == ElderSelfDecision.selfReminder) {
        await LocalNotificationsHelper.showSelfReminder();
        await _firestoreService.markSelfReminderShown(elderUid);
      }
    } catch (_) {}
  }

  Future<void> resolveSOSAlert(String elderUid) async {
    _isResolvingSOS = true;
    notifyListeners();
    try {
      await _firestoreService.resolveSOSAlert(elderUid);
    } catch (e) {
      _isResolvingSOS = false;
      notifyListeners();
      rethrow;
    }
    _isResolvingSOS = false;
    notifyListeners();
  }

  Future<void> checkIn(String elderUid, {bool isEmergency = false}) async {
    _setLoading(true);
    try {
      await _firestoreService.recordCheckin(elderUid, isEmergency: isEmergency);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> linkContact(String elderUid, String contactEmail) async {
    _setLoading(true);
    try {
      await _firestoreService.linkContact(elderUid, contactEmail);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeContact(String elderUid, String contactId) async {
    _setLoading(true);
    try {
      await _firestoreService.removeContact(elderUid, contactId);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
