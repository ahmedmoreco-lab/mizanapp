import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';

/// Preserved SoulPing Firebase bootstrap reference.
///
/// Mizan does not call this function. It remains here so the existing Firebase
/// startup-race workaround is not lost while a separate Mizan Firebase project
/// and backend migration plan are being prepared.
Future<void> initializeLegacySoulPingFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  const maxAttempts = 5;
  for (var attempt = 1;; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (attempt > 1) {
        debugPrint('Firebase initialized after $attempt attempts.');
      }
      return;
    } on PlatformException catch (error) {
      if (error.code == 'channel-error' && attempt < maxAttempts) {
        debugPrint(
          'Firebase init channel-error (attempt $attempt/$maxAttempts); '
          'retrying after plugin registration settles…',
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
        continue;
      }
      rethrow;
    }
  }
}
