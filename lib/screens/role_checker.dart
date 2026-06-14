import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/background_check_service.dart';
import 'contact_home_screen.dart';
import 'elder_home_screen.dart';

class RoleChecker extends StatefulWidget {
  const RoleChecker({super.key});

  @override
  State<RoleChecker> createState() => _RoleCheckerState();
}

class _RoleCheckerState extends State<RoleChecker> {
  Future<DocumentSnapshot>? _roleFuture;
  String? _cachedUid;
  bool _periodicTaskRegistered = false;

  Future<DocumentSnapshot> _fetchRole(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Future<void> _ensurePeriodicTask() async {
    if (_periodicTaskRegistered) return;
    if (kIsWeb || !Platform.isAndroid) return;
    _periodicTaskRegistered = true;
    await BackgroundCheckScheduler.registerPeriodicTask();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final uid = authSnapshot.data!.uid;

        // Only create a new future when the uid actually changes
        if (uid != _cachedUid) {
          _cachedUid = uid;
          _roleFuture = _fetchRole(uid);
        }
        // Register the workmanager periodic check once per session.
        _ensurePeriodicTask();

        return FutureBuilder<DocumentSnapshot>(
          future: _roleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Failed to load profile. Please try again.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _cachedUid = null;
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final role = data?['role']?.toString().toLowerCase().trim();

            debugPrint('Role loaded: $role');

            if (role == 'elder') {
              return const ElderHomeScreen();
            } else {
              return const ContactHomeScreen();
            }
          },
        );
      },
    );
  }
}
