import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_checker.dart';
import 'providers/auth_provider.dart';
import 'providers/elder_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/monitoring_provider.dart';
import 'services/background_check_service.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';


const _brandNavy = Color(0xFF123247);
const _brandTeal = Color(0xFF2F6B73);
const _brandCream = Color(0xFFF6F3EC);
const _brandWhite = Color(0xFFFFFFFF);
const _brandGold = Color(0xFFE0B14C);
const _brandText = Color(0xFF1D2A33);

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

  if (!kIsWeb && Platform.isAndroid) {
    try {
      FlutterForegroundTask.initCommunicationPort();
    } catch (e) {
      debugPrint('Foreground task port init skipped: $e');
    }
    // Local-notification channel + workmanager periodic check (Blaze-free fallback).
    await LocalNotificationsHelper.ensureReady();
    await BackgroundCheckScheduler.initWorkmanager();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ElderProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _brandNavy,
      onPrimary: _brandWhite,
      secondary: _brandGold,
      onSecondary: _brandText,
      error: const Color(0xFFB3261E),
      onError: _brandWhite,
      surface: _brandWhite,
      onSurface: _brandText,
    );

    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SoulPing Care',
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: _brandCream,
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandNavy,
          foregroundColor: _brandWhite,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _brandWhite,
          ),
        ),
        cardTheme: CardThemeData(
          color: _brandWhite,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _brandWhite,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _brandText,
          ),
          hintStyle: const TextStyle(
            fontSize: 17,
            color: Color(0xFF5A6871),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _brandTeal, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _brandTeal, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _brandNavy, width: 2.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandNavy,
            foregroundColor: _brandWhite,
            minimumSize: const Size.fromHeight(64),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandNavy,
            side: const BorderSide(color: _brandNavy, width: 2),
            minimumSize: const Size.fromHeight(64),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _brandNavy,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _brandNavy,
          contentTextStyle: const TextStyle(
            fontSize: 16,
            color: _brandWhite,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: _brandText,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _brandText,
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _brandText,
          ),
          bodyLarge: TextStyle(
            fontSize: 20,
            color: _brandText,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            fontSize: 18,
            color: _brandText,
            height: 1.4,
          ),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const RoleChecker(),
      },
    );
  }
}
