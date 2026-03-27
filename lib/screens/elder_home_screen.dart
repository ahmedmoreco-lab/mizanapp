import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/set_contact_screen.dart';
import '../services/checkin_service.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  final CheckInService service = CheckInService();

  String? lastCheckIn;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadLastCheckIn();
  }

  // 🔹 Load last check-in from service
  Future<void> loadLastCheckIn() async {
    try {
      final result = await service.getLastCheckIn();

      if (!mounted) return;

      setState(() {
        lastCheckIn =
            result != null ? result.toDate().toLocal().toString() : "No check-in yet";
      });
    } catch (e) {
      showMessage("Error loading data: $e");
    }
  }

  // 🔹 Record new check-in
  Future<void> recordCheckIn() async {
    setState(() => isLoading = true);

    try {
      await service.recordCheckIn();

      final result = await service.getLastCheckIn();

      if (!mounted) return;

      setState(() {
        lastCheckIn = result?.toDate().toLocal().toString();
      });

      showMessage("✅ Check-in recorded!");
    } catch (e) {
      showMessage("❌ Error: $e");
    }

    setState(() => isLoading = false);
  }

  // 🔹 Run inactivity check
  Future<void> runSafetyCheck() async {
    try {
      final result = await service.getLastCheckIn();

      if (result == null) {
        showMessage("No check-in data available.");
        return;
      }

      final inactive = service.isInactive(result);

      showMessage(
        inactive
            ? "⚠ You missed your check-in!"
            : "✅ You are safe",
      );
    } catch (e) {
      showMessage("Error: $e");
    }
  }

  // 🔹 Snackbar helper
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SoulPing Care"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🧓 Title
            const Text(
              "Daily Check-In",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // 📅 Last Check-In
            Text(
              "Last Check-In:",
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              lastCheckIn ?? "Loading...",
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // ✅ Check-In Button
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: recordCheckIn,
                      child: const Text(
                        "I’m OK",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // 🔍 Safety Check Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SetContactScreen(),
                    ),
                  );
                },
                child: const Text("Set Trusted Contact"),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: runSafetyCheck,
                child: const Text(
                  "Run Safety Check",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}