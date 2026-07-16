import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/mizan_constants.dart';
import 'core/services/mizan_firebase_bootstrap.dart';
import 'core/widgets/mizan_navigation_shell.dart';
import 'features/today/providers/daily_plan_provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MizanFirebaseBootstrap.initializeIfSupported();
  runApp(const MizanApp());
}

/// Local-only application bootstrap for the Mizan prototype.
///
/// Authentication, remote notifications, persistence, and the legacy safety
/// monitor intentionally remain outside this widget tree. Firebase Core is
/// initialized only where the new Mizan project can be selected safely.
class MizanApp extends StatelessWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => DailyPlanProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      home: const MizanNavigationShell(),
      restorationScopeId: MizanConstants.appName,
    );
  }
}
