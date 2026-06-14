import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/contact_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/checkin_model.dart';
import '../utils/theme.dart';
import 'auth/account_settings_screen.dart';
import 'package:intl/intl.dart';

class ContactHomeScreen extends StatefulWidget {
  const ContactHomeScreen({super.key});

  @override
  State<ContactHomeScreen> createState() => _ContactHomeScreenState();
}

class _ContactHomeScreenState extends State<ContactHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = Provider.of<AppAuthProvider>(context, listen: false)
          .userModel
          ?.uid;
      if (uid != null) {
        Provider.of<ContactProvider>(context, listen: false)
            .startWatchingForAlerts(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.monitoringDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.accountSettings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
            tooltip: l.logout,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: Provider.of<ContactProvider>(context, listen: false)
              .streamLinkedElders(user.uid),
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
                      Icon(
                        Icons.people_alt_outlined,
                        size: 80,
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l.noEldersLinked,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Hi ${user.name != null && user.name!.isNotEmpty ? user.name : user.email.split('@')[0]},\n"
                        "${l.noEldersDesc.replaceFirst('your email', "'${user.email}'")}",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: elders.length,
                itemBuilder: (context, index) {
                  final elder = elders[index];
                  return _ElderStatusCard(
                    elder: elder,
                    firestoreService: _firestoreService,
                  );
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

  void _showThresholdDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.setAlertThreshold),
        content: Text(
          "${l.alertMeIf} ${elder.name ?? 'this elder'} ${l.missesCheckIn}",
        ),
        actions: [
          for (final hours in [4, 8, 12, 24, 48])
            TextButton(
              onPressed: () async {
                try {
                  await firestoreService.updateInactivityThreshold(
                      elder.uid, hours);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(
                "${hours}h",
                style: TextStyle(
                  fontWeight: elder.inactivityThresholdHours == hours
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: elder.inactivityThresholdHours == hours
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CheckinModel?>(
      stream: firestoreService.streamLastCheckin(elder.uid),
      builder: (context, snapshot) {
        final checkin = snapshot.data;

        final l = AppLocalizations.of(context);
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
              // Coloured status bar at top of card
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
                    // — Header: name + threshold button —
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person,
                              color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            elder.name ?? elder.email.split('@')[0],
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.av_timer_rounded),
                          color: AppTheme.textMuted,
                          tooltip: 'Set Inactivity Threshold',
                          onPressed: () => _showThresholdDialog(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // — Status box —
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
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
                                  "${l.lastActive} $lastTime",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textMain
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // — Weekly Safety Insights (all users) —
                    StreamBuilder<List<CheckinModel>>(
                      stream: firestoreService.streamWeeklyCheckins(elder.uid),
                      builder: (context, insightSnap) {
                        if (!insightSnap.hasData) return const SizedBox.shrink();
                        final weeklyCheckins = insightSnap.data!;

                        final daysWithCheckin = weeklyCheckins
                            .fold<Set<String>>({}, (set, c) {
                          set.add(DateFormat('yyyy-MM-dd').format(c.timestamp));
                          return set;
                        }).length;

                        final safeDays =
                            daysWithCheckin > 7 ? 7 : daysWithCheckin;
                        final missedDays = 7 - safeDays;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l.weeklySafetyInsights,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                if (elder.isPremium) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star_rounded,
                                      size: 14, color: Color(0xFFE0B14C)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.analytics_rounded,
                                    size: 20, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Last 7 days: $safeDays/7 safe",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (missedDays > 0) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    "• Missed $missedDays days",
                                    style: const TextStyle(
                                      color: AppTheme.statusAlert,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      },
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
