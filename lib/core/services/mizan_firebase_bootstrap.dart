import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'mizan_firebase_options.dart';

class MizanFirebaseBootstrap {
  MizanFirebaseBootstrap._();

  /// Initializes only platforms that can safely use the new Mizan web app.
  ///
  /// Android and iOS remain local-only because their supplied Firebase files
  /// target different package/bundle identifiers than this Flutter copy.
  static Future<void> initializeIfSupported() async {
    final supportsWebConfiguration = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (!supportsWebConfiguration || Firebase.apps.isNotEmpty) return;

    try {
      await Firebase.initializeApp(options: MizanFirebaseOptions.web);
    } catch (error) {
      debugPrint(
        'Mizan Firebase Core was unavailable; continuing with local data: '
        '$error',
      );
    }
  }
}
