import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/elder_provider.dart';
import '../services/firestore_service.dart';
import '../models/checkin_model.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';
import 'set_contact_screen.dart';
import 'package:intl/intl.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _handleCheckIn(String uid, {bool isEmergency = false}) async {
    try {
      await Provider.of<ElderProvider>(context, listen: false).checkIn(uid, isEmergency: isEmergency);
      _showMessage(isEmergency ? 'Emergency Alert Sent!' : 'Check-in successful!');
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) return const Scaffold(body: Center(child: Text("Loading...")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hi ${user.name != null && user.name!.isNotEmpty ? user.name : user.email.split('@')[0]}',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Prominent Trusted Contact Widget
              Card(
                color: user.trustedContactId == null ? AppTheme.statusAlert.withOpacity(0.1) : AppTheme.primary.withOpacity(0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: user.trustedContactId == null ? AppTheme.statusAlert : AppTheme.primary.withOpacity(0.3), width: 2),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetContactScreen())),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.contact_phone_rounded, size: 40, color: user.trustedContactId == null ? AppTheme.statusAlert : AppTheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Trusted Contact",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                              ),
                              Text(
                                user.trustedContactId == null ? "Tap to setup immediately!" : "Tap to view or change",
                                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Card with Stream
              StreamBuilder<CheckinModel?>(
                stream: _firestoreService.streamLastCheckin(user.uid),
                builder: (context, snapshot) {
                  final checkin = snapshot.data;
                  final hasCheckedIn = checkin != null;
                  
                  String statusText = "No check-in yet";
                  Color statusColor = AppTheme.statusNeutral;
                  IconData statusIcon = Icons.help_outline_rounded;

                  if (hasCheckedIn) {
                    final timePassed = DateTime.now().difference(checkin.timestamp);
                    if (timePassed.inHours < user.inactivityThresholdHours) {
                      statusColor = AppTheme.statusSafe;
                      statusText = "You are marked SAFE";
                      statusIcon = Icons.check_circle_rounded;
                    } else {
                      statusColor = AppTheme.statusAlert;
                      statusText = "Missed Check-in (>${user.inactivityThresholdHours}h)";
                      statusIcon = Icons.error_rounded;
                    }
                  }

                  return Card(
                    color: statusColor.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: statusColor, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(statusIcon, size: 64, color: statusColor),
                          const SizedBox(height: 16),
                          Text(statusText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor)),
                          if (hasCheckedIn) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Last: ${DateFormat.yMMMd().add_jm().format(checkin.timestamp)}",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),
              
              // Big Check In Button
              Consumer<ElderProvider>(
                builder: (context, elderProvider, child) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 70,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: elderProvider.isLoading ? null : () => _handleCheckIn(user.uid),
                          child: elderProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.waving_hand_rounded, size: 28),
                                    SizedBox(width: 16),
                                    Text("I'm OK", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Huge Emergency Button
                      SizedBox(
                        height: 70,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.statusAlert,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: elderProvider.isLoading ? null : () => _handleCheckIn(user.uid, isEmergency: true),
                          child: elderProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_rounded, size: 28),
                                    SizedBox(width: 16),
                                    Text("EMERGENCY SOS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}