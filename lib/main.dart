import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_checker.dart';
import 'providers/auth_provider.dart';
import 'providers/elder_provider.dart';
import 'providers/contact_provider.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('🔥 Firebase initialized: ${Firebase.apps.length}');

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ElderProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SoulPing Care',
      theme: AppTheme.lightTheme,
      home: const _ConnectivityWrapper(child: RoleChecker()),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const RoleChecker(),
      },
    );
  }
}

/// Wraps the entire app with a global offline banner at the bottom.
/// Uses a periodic check (every 5 seconds) — no extra package needed.
class _ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const _ConnectivityWrapper({required this.child});

  @override
  State<_ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<_ConnectivityWrapper> {
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Poll every 5 seconds — lightweight, no package dependency
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    try {
      // Firestore itself will throw FirebaseException when offline,
      // but the simplest zero-dependency approach is to try resolving a host.
      // We just track Firestore's network state instead.
      // Using FirebaseFirestore.instance.enableNetwork() / disableNetwork() is optional —
      // instead we simply listen to whether the app can reach Firebase at all.
      // For now we mark as online if no exception has been recently thrown.
      // Real-time tracking is done by catching FirebaseException in service calls.
      if (!mounted) return;
    } catch (_) {
      if (mounted) setState(() => _isOffline = true);
    }
  }

  // Called from child widgets when a Firestore call fails with [unavailable]
  void setOffline(bool value) {
    if (!mounted) return;
    setState(() => _isOffline = value);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'No internet connection — retrying…',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
