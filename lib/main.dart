import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = AppState();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const AhmedOsApp(),
    ),
  );

  // Loading after the first frame keeps launch instant; the app shows a
  // spinner for the few milliseconds the document takes to read.
  await state.load();
}
