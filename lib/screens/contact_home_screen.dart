import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/contact_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/checkin_model.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class ContactHomeScreen extends StatefulWidget {
  const ContactHomeScreen({super.key});

  @override
  State<ContactHomeScreen> createState() => _ContactHomeScreenState();
}

class _ContactHomeScreenState extends State<ContactHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: Provider.of<ContactProvider>(context, listen: false).streamLinkedElders(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final elders = snapshot.data;
            if (elders == null || elders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined, size: 80, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 24),
                      Text("No Elders Linked", style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 16),
                      Text(
                        "Hi ${user.name != null && user.name!.isNotEmpty ? user.name : user.email.split('@')[0]},\nan elder must add your email ('${user.email}') in their app to link their account to yours.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {}); // Re-trigger stream builder UI
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: elders.length,
                itemBuilder: (context, index) {
                  final elder = elders[index];
                  return _ElderStatusCard(elder: elder, firestoreService: _firestoreService);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ElderStatusCard extends StatelessWidget {
  final UserModel elder;
  final FirestoreService firestoreService;

  const _ElderStatusCard({
    required this.elder,
    required this.firestoreService,
  });

  void _showThresholdDialog(BuildContext context, UserModel elder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Alarm Threshold"),
          content: Text("Alert me if ${elder.name ?? 'this elder'} misses a check-in for more than:"),
          actions: [
            for (final hours in [4, 8, 12, 24, 48])
              TextButton(
                onPressed: () {
                  firestoreService.updateInactivityThreshold(elder.uid, hours);
                  Navigator.pop(context);
                },
                child: Text(
                  "${hours}h",
                  style: TextStyle(
                    fontWeight: elder.inactivityThresholdHours == hours ? FontWeight.bold : FontWeight.normal,
                    color: elder.inactivityThresholdHours == hours ? AppTheme.primary : AppTheme.textMuted,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CheckinModel?>(
      stream: firestoreService.streamLastCheckin(elder.uid),
      builder: (context, snapshot) {
        final checkin = snapshot.data;
        
        Color statusColor = AppTheme.statusNeutral;
        String statusText = "No data yet";
        IconData statusIcon = Icons.help_outline;
        String lastTime = "Never";

        if (checkin != null) {
          final timePassed = DateTime.now().difference(checkin.timestamp);
          lastTime = DateFormat.yMMMd().add_jm().format(checkin.timestamp);
          
          if (checkin.isEmergency) {
            statusColor = AppTheme.statusAlert;
            statusText = "🚨 EMERGENCY SOS TRIGGERED 🚨";
            statusIcon = Icons.warning_rounded;
          } else if (timePassed.inHours < elder.inactivityThresholdHours) {
            statusColor = AppTheme.statusSafe;
            statusText = "Safe (Checked in <${elder.inactivityThresholdHours}h ago)";
            statusIcon = Icons.check_circle_rounded;
          } else {
            statusColor = AppTheme.statusAlert;
            statusText = "ALERT: Missed Check-in";
            statusIcon = Icons.warning_rounded;
          }
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: statusColor,
                height: 8,
                width: double.infinity,
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            elder.name ?? elder.email.split('@')[0], // show name or email prefix
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.av_timer_rounded),
                          color: AppTheme.textMuted,
                          tooltip: 'Set Inactivity Threshold',
                          onPressed: () => _showThresholdDialog(context, elder),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Last active: $lastTime",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textMain.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
