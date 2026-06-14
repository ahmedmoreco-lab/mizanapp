import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/background_check_service.dart';
import '../services/firestore_service.dart';
import '../services/local_notification_service.dart';

class ContactProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<UserModel>>? _eldersSub;
  final Map<String, UserModel> _elderCache = {};
  final Map<String, StreamSubscription<DocumentSnapshot>> _statusSubs = {};

  Stream<List<UserModel>> streamLinkedElders(String contactUid) {
    return _firestoreService.streamLinkedElders(contactUid);
  }

  /// Watches every linked Elder's `users/{id}` + `status/current` doc and
  /// fires local SOS / inactivity notifications instantly while the app is
  /// open. De-duplication is handled inside [BackgroundCheckService].
  void startWatchingForAlerts(String contactUid) {
    _eldersSub?.cancel();
    _eldersSub = streamLinkedElders(contactUid).listen((elders) {
      final liveIds = elders.map((e) => e.uid).toSet();
      _elderCache
        ..clear()
        ..addEntries(elders.map((e) => MapEntry(e.uid, e)));

      // Drop subscriptions for elders that are no longer linked.
      final toRemove = _statusSubs.keys
          .where((id) => !liveIds.contains(id))
          .toList(growable: false);
      for (final id in toRemove) {
        _statusSubs.remove(id)?.cancel();
      }

      // Subscribe to any newly added Elder.
      for (final elder in elders) {
        if (_statusSubs.containsKey(elder.uid)) continue;
        _statusSubs[elder.uid] = _firestoreService
            .streamElderStatus(elder.uid)
            .listen((statusSnap) => _evaluateForElder(elder.uid, statusSnap));
      }
    });
  }

  Future<void> _evaluateForElder(
    String elderId,
    DocumentSnapshot statusSnap,
  ) async {
    if (!statusSnap.exists) return;
    final elder = _elderCache[elderId];
    if (elder == null) return;

    final status = (statusSnap.data() as Map<String, dynamic>?) ?? const {};

    // `lastCheckIn` lives on the user doc, not on UserModel — read it raw.
    Map<String, dynamic> elderRaw;
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .get();
      elderRaw = userSnap.data() ?? const {};
    } catch (_) {
      elderRaw = const {};
    }

    final decisions = BackgroundCheckService.evaluateContactView(
      now: DateTime.now(),
      elder: elderRaw,
      status: status,
    );

    final elderName = (elder.name?.isNotEmpty == true)
        ? elder.name!
        : elder.email.split('@').first;

    if (decisions.contains(ContactDecision.sos)) {
      await LocalNotificationsHelper.showSos(elderName: elderName);
      await _firestoreService.markSosNotified(elderId);
    }
    if (decisions.contains(ContactDecision.inactivity)) {
      await LocalNotificationsHelper.showInactivity(
        elderName: elderName,
        hours: elder.inactivityThresholdHours,
      );
      await _firestoreService.markInactivityNotified(elderId);
    }
  }

  void stopWatching() {
    _eldersSub?.cancel();
    _eldersSub = null;
    for (final sub in _statusSubs.values) {
      sub.cancel();
    }
    _statusSubs.clear();
    _elderCache.clear();
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
