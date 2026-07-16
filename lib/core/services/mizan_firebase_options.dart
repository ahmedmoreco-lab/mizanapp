import 'package:firebase_core/firebase_core.dart';

/// Public client configuration for the new Mizan Firebase web application.
///
/// Mobile configuration is intentionally absent until the Flutter package and
/// bundle identifiers match the Android/iOS apps registered in Firebase.
class MizanFirebaseOptions {
  MizanFirebaseOptions._();

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAOTEHiRmdG4aEHWwg5mypz1rCbcrRxWss',
    appId: '1:55199742804:web:b3f204b94b715263e066c1',
    messagingSenderId: '55199742804',
    projectId: 'mizan-app-7fa3f',
    authDomain: 'mizan-app-7fa3f.firebaseapp.com',
    storageBucket: 'mizan-app-7fa3f.firebasestorage.app',
    measurementId: 'G-8E1YQSNB3P',
  );
}
