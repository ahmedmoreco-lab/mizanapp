import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactHomeScreen extends StatelessWidget {
  const ContactHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Elder Monitoring"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('trustedContactId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No linked elder found"),
            );
          }

          final elderDoc = snapshot.data!.docs.first;
          final elderData = elderDoc.data() as Map<String, dynamic>;

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('checkins')
                .where('userId', isEqualTo: elderDoc.id)
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get(),
            builder: (context, checkinSnapshot) {
              if (checkinSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              String status = "No check-ins yet";
              Color statusColor = Colors.grey;

              if (checkinSnapshot.hasData &&
                  checkinSnapshot.data!.docs.isNotEmpty) {
                final checkin = checkinSnapshot.data!.docs.first;
                final timestamp = checkin['timestamp'];

                if (timestamp != null) {
                  final lastCheck =
                      (timestamp as Timestamp).toDate();
                  final difference =
                      DateTime.now().difference(lastCheck).inHours;

                  if (difference <= 24) {
                    status = "✅ SAFE";
                    statusColor = Colors.green;
                  } else {
                    status = "🚨 ALERT (Missed check-in)";
                    statusColor = Colors.red;
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 80),

                    const SizedBox(height: 20),

                    Text(
                      "Elder Email: ${elderData['email']}",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}