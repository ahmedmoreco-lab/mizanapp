import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/cloud_store.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'ui/auth/auth_page.dart';

class AhmedOsBootstrap extends StatefulWidget {
  const AhmedOsBootstrap({super.key});

  @override
  State<AhmedOsBootstrap> createState() => _AhmedOsBootstrapState();
}

class _AhmedOsBootstrapState extends State<AhmedOsBootstrap> {
  StreamSubscription<User?>? _authSubscription;
  AppState? _appState;
  User? _user;
  Object? _firebaseError;
  Object? _dataError;
  bool _firebaseReady = false;
  bool _sessionLoading = true;
  int _sessionGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeFirebase());
  }

  Future<void> _initializeFirebase() async {
    setState(() {
      _firebaseError = null;
      _firebaseReady = false;
    });
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 20));
      }
      await _connectAuth();
    } catch (error) {
      var reportedError = error;
      if (Firebase.apps.isNotEmpty) {
        try {
          await _connectAuth();
          return;
        } catch (fallbackError) {
          reportedError = fallbackError;
        }
      }
      if (!mounted) return;
      setState(() {
        _firebaseError = reportedError;
        _sessionLoading = false;
      });
    }
  }

  Future<void> _connectAuth() async {
    final auth = FirebaseAuth.instance;
    await _authSubscription?.cancel();
    _authSubscription = auth.authStateChanges().listen(
      _handleUser,
      onError: (Object error) {
        if (mounted) setState(() => _firebaseError = error);
      },
    );
    if (!mounted) return;
    setState(() => _firebaseReady = true);
    await _handleUser(auth.currentUser);
  }

  Future<void> _handleUser(User? user) async {
    final generation = ++_sessionGeneration;
    final previousState = _appState;
    _appState = null;
    previousState?.dispose();

    if (!mounted) return;
    setState(() {
      _user = user;
      _dataError = null;
      _sessionLoading = user != null;
    });
    if (user == null) return;

    final state = AppState(
      store: CloudStore(
        firestore: FirebaseFirestore.instance,
        user: user,
      ),
    );
    try {
      await state.load();
      if (!mounted || generation != _sessionGeneration) {
        state.dispose();
        return;
      }
      setState(() {
        _appState = state;
        _sessionLoading = false;
      });
    } catch (error) {
      state.dispose();
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        _dataError = error;
        _sessionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseError != null) {
      return _BootstrapMaterial(
        child: _StatusPage(
          title: 'Could not connect',
          message: _firebaseErrorMessage(_firebaseError!),
          actionLabel: 'Retry',
          onAction: _initializeFirebase,
        ),
      );
    }

    if (!_firebaseReady || _sessionLoading) {
      return const _BootstrapMaterial(child: _StatusPage.loading());
    }

    if (_user == null) {
      return _BootstrapMaterial(
        child: AuthPage(auth: FirebaseAuth.instance),
      );
    }

    if (_dataError != null || _appState == null) {
      return _BootstrapMaterial(
        child: _StatusPage(
          title: 'Cloud data unavailable',
          message: 'Reconnect before opening this account on a new device.',
          actionLabel: 'Retry',
          onAction: () => _handleUser(_user),
          secondaryLabel: 'Sign out',
          onSecondary: FirebaseAuth.instance.signOut,
        ),
      );
    }

    return ChangeNotifierProvider<AppState>.value(
      value: _appState!,
      child: const AhmedOsApp(),
    );
  }

  String _firebaseErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'Firebase startup timed out. Check your connection and retry.';
    }
    if (error is FirebaseException) {
      return '${error.plugin}/${error.code}: '
          '${error.message ?? 'Firebase could not start.'}';
    }
    final detail = error.toString();
    final shortened =
        detail.length > 180 ? '${detail.substring(0, 180)}...' : detail;
    return 'Firebase could not start: $shortened';
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel() ?? Future<void>.value());
    _appState?.dispose();
    super.dispose();
  }
}

class _BootstrapMaterial extends StatelessWidget {
  const _BootstrapMaterial({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ahmed OS',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: child,
      );
}

class _StatusPage extends StatelessWidget {
  const _StatusPage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  }) : loading = false;

  const _StatusPage.loading()
      : title = 'Ahmed OS',
        message = '',
        actionLabel = '',
        onAction = null,
        secondaryLabel = null,
        onSecondary = null,
        loading = true;

  final String title;
  final String message;
  final String actionLabel;
  final FutureOr<void> Function()? onAction;
  final String? secondaryLabel;
  final FutureOr<void> Function()? onSecondary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.x24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: AppType.subScreenTitle.copyWith(color: t.ink)),
                  if (loading) ...[
                    const SizedBox(height: Sp.x20),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.faint,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: Sp.x8),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: AppType.body.copyWith(color: t.muted)),
                    const SizedBox(height: Sp.x20),
                    FilledButton(
                      onPressed: onAction == null
                          ? null
                          : () {
                              onAction!();
                            },
                      child: Text(actionLabel),
                    ),
                    if (secondaryLabel != null) ...[
                      const SizedBox(height: Sp.x8),
                      TextButton(
                        onPressed: onSecondary == null
                            ? null
                            : () {
                                onSecondary!();
                              },
                        child: Text(secondaryLabel!),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
