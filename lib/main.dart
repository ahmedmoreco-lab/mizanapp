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
  
  // Initialize Firebase First
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔥 Firebase initialized: ${Firebase.apps.length}");

  // Optional: Initialize Notifications
  try {
    final notificationService = NotificationService();
    // Awaiting this without native setup can crash the app before runApp
    // await notificationService.initialize();
  } catch (e) {
    print("Notification error: $e");
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
      home: const RoleChecker(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const RoleChecker(),
      },
    );
  }
}
