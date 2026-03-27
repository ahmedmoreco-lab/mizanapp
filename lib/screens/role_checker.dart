import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'contact_screen.dart'; // if not renamed
import 'elder_home_screen.dart';
import 'contact_home_screen.dart';

class RoleChecker extends StatelessWidget {
  const RoleChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 🔄 Waiting for auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text("User not logged in")),
          );
        }

        final user = authSnapshot.data!;
        final uid = user.uid;

        // 🔥 Now fetch Firestore
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final role = data?['role'];

            print("🔥 ROLE: $role");

            if (role != null &&
                role.toString().toLowerCase().trim() == 'elder') {
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