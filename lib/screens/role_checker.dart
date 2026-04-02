import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'elder_home_screen.dart';
import 'contact_home_screen.dart';
import 'login_screen.dart';

class RoleChecker extends StatelessWidget {
  const RoleChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.firebaseUser == null || authProvider.userModel == null) {
          return const LoginScreen();
        }

        if (authProvider.userModel!.isElder) {
          return const ElderHomeScreen();
        } else {
          return const ContactHomeScreen();
        }
      },
    );
  }
}