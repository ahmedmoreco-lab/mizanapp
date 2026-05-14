import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetContactScreen extends StatefulWidget {
  const SetContactScreen({super.key});

  @override
  State<SetContactScreen> createState() => _SetContactScreenState();
}

class _SetContactScreenState extends State<SetContactScreen> {
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  String message = "";

  // 🔥 MAIN FUNCTION (FULL FLOW)
  Future<void> linkTrustedContact() async {
    final email = emailController.text.trim();
    // ✅ Validate input
    if (email.isEmpty) {
      setState(() => message = "⚠️ Please enter an email");
      return;
    }

    try {
      setState(() {
        isLoading = true;
        message = "";
      });

      // 👤 Get current elder
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        setState(() => message = "❌ User not logged in");
        return;
      }

      final elderId = currentUser.uid;

      // 🔍 Search for contact by email
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        setState(() => message = "❌ No user found with this email");
        return;
      }

      // ✅ Get contact data
      final contactDoc = query.docs.first;
      final contactId = contactDoc.id;
      final contactData = contactDoc.data();

      // 🚫 Prevent linking yourself
      if (contactId == elderId) {
        setState(() => message = "⚠️ You cannot link yourself");
        return;
      }

      // 🚫 Ensure it's a contact account
      if (contactData['role'] != 'contact') {
        setState(() => message = "⚠️ This user is not a trusted contact");
        return;
      }

      // 🔗 Save link in Firestore — update BOTH the legacy field AND the array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .update({
        'trustedContactId': contactId,
        'trustedContacts': FieldValue.arrayUnion([contactId]),
        'escalationOrder': FieldValue.arrayUnion([contactId]),
      });

      setState(() {
        message = "✅ Trusted contact linked successfully!";
      });

      // 🚀 Navigate after success
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      });

    } catch (e) {
      setState(() => message = "❌ Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // 🎨 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Trusted Contact"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_alt_1,
                size: 80, color: Colors.blue),

            const SizedBox(height: 20),

            const Text(
              "Enter Trusted Contact Email",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: linkTrustedContact,
                      child: const Text(
                        "Link Contact",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: message.contains("✅")
                    ? Colors.green
                    : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}