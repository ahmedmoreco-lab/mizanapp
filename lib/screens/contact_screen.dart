import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactHomeScreen extends StatelessWidget {
  const ContactHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final elderId = data['linkedElderId'];

        if (elderId == null) {
          return const Scaffold(
            body: Center(child: Text("No elder linked yet")),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(elderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final elderData =
                snapshot.data!.data() as Map<String, dynamic>;

            final lastCheck = elderData['lastCheckIn'];

            bool isSafe = true;

            if (lastCheck != null) {
              final lastTime = lastCheck.toDate();
              final diff = DateTime.now().difference(lastTime);

              isSafe = diff.inHours < 24;
            }

            return Scaffold(
              appBar: AppBar(title: const Text("Monitoring Dashboard")),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      isSafe ? "🟢 Elder is Safe" : "🔴 Missed Check-In!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isSafe ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Last Check-In:",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Text(
                      lastCheck != null
                          ? lastCheck.toDate().toString()
                          : "No data",
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}