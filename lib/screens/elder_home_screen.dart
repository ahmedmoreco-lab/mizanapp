import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/elder_provider.dart';
import '../services/firestore_service.dart';
import '../models/checkin_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import 'set_contact_screen.dart';
import 'premium_paywall_screen.dart';
import 'auth/account_settings_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? AppTheme.statusAlert : null,
    ));
  }

  Future<void> _handleCheckIn(String uid, {bool isEmergency = false}) async {
    // 🔐 Guard: must have at least one trusted contact
    final user = Provider.of<AppAuthProvider>(context, listen: false).userModel;
    if (user == null || user.trustedContacts.isEmpty) {
      _showMessage('Please add a trusted contact first', isError: true);
      return;
    }
    try {
      await Provider.of<ElderProvider>(context, listen: false)
          .checkIn(uid, isEmergency: isEmergency);
      _showMessage(isEmergency ? '🚨 Emergency Alert Sent!' : '✅ Check-in successful!');
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _confirmEmergency(String uid) async {
    // 🔐 Guard: must have at least one trusted contact
    final user = Provider.of<AppAuthProvider>(context, listen: false).userModel;
    if (user == null || user.trustedContacts.isEmpty) {
      _showMessage('Please add a trusted contact first', isError: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Confirm Emergency'),
          ],
        ),
        content: const Text(
          'This will immediately alert your Trusted Contacts.\n\nAre you sure?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Send SOS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _handleCheckIn(uid, isEmergency: true);
    }
  }

  void _showReminderDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _ReminderDialog(user: user, firestoreService: _firestoreService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasContacts = user.trustedContacts.isNotEmpty;
    final contactCount = user.trustedContacts.length;
    final maxContacts = user.isPremium ? 5 : 3;

    final displayName = (user.name != null && user.name!.isNotEmpty)
        ? user.name!
        : user.email.split('@')[0];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          if (user.isPremium) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text('PRO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(
              icon: Stack(children: [
                const Icon(Icons.notifications_outlined),
                if (user.customCheckInTimes.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppTheme.statusSafe,
                          shape: BoxShape.circle),
                    ),
                  ),
              ]),
              tooltip: 'Check-in Reminders',
              onPressed: () => _showReminderDialog(user),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Account Settings',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Greeting ──────────────────────────────────────────
                      Text(
                        'Hello, $displayName 👋',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'How are you feeling today?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textMuted, fontSize: 15),
                      ),
                      const SizedBox(height: 20),

                      // ── Status Card (stream) ───────────────────────────────
                      StreamBuilder<CheckinModel?>(
                        stream: _firestoreService.streamLastCheckin(user.uid),
                        builder: (context, snapshot) {
                          final checkin = snapshot.data;
                          final hasCheckedIn = checkin != null;

                          String statusText = 'No check-in recorded yet';
                          Color statusColor = AppTheme.statusNeutral;
                          IconData statusIcon = Icons.help_outline_rounded;
                          String? subText;

                          if (hasCheckedIn) {
                            final timePassed =
                                DateTime.now().difference(checkin.timestamp);
                            subText =
                                'Last: ${DateFormat.yMMMd().add_jm().format(checkin.timestamp)}';
                            if (timePassed.inHours <
                                user.inactivityThresholdHours) {
                              statusColor = AppTheme.statusSafe;
                              statusText = 'You are Safe ✓';
                              statusIcon = Icons.check_circle_rounded;
                            } else {
                              statusColor = AppTheme.statusAlert;
                              statusText =
                                  'Missed Check-in (>${user.inactivityThresholdHours}h)';
                              statusIcon = Icons.error_rounded;
                            }
                          }

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.35),
                                  width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(statusIcon,
                                      size: 28, color: statusColor),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(statusText,
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor)),
                                      if (subText != null) ...[
                                        const SizedBox(height: 3),
                                        Text(subText,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textMuted)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Trusted Contacts Card ─────────────────────────────
                      _TappableCard(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const SetContactScreen())),
                        borderColor: hasContacts
                            ? AppTheme.primary.withValues(alpha: 0.25)
                            : AppTheme.statusAlert.withValues(alpha: 0.6),
                        backgroundColor: hasContacts
                            ? AppTheme.primary.withValues(alpha: 0.04)
                            : AppTheme.statusAlert.withValues(alpha: 0.05),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (hasContacts
                                        ? AppTheme.primary
                                        : AppTheme.statusAlert)
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                hasContacts
                                    ? Icons.group_rounded
                                    : Icons.person_add_alt_1_rounded,
                                size: 26,
                                color: hasContacts
                                    ? AppTheme.primary
                                    : AppTheme.statusAlert,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasContacts
                                        ? 'Trusted Contacts ($contactCount/$maxContacts)'
                                        : 'No Trusted Contact',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textMain),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    !hasContacts
                                        ? '⚠️ Required for safety alerts!'
                                        : contactCount < maxContacts
                                            ? 'Tap to manage · Add up to $maxContacts'
                                            : 'Safety network complete',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: !hasContacts
                                            ? AppTheme.statusAlert
                                            : AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textMuted),
                          ],
                        ),
                      ),

                      // ── Active Reminders Row (Premium) ────────────────────
                      if (user.isPremium &&
                          user.customCheckInTimes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showReminderDialog(user),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.alarm_on_rounded,
                                    color: AppTheme.primary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Reminders: ${user.customCheckInTimes.join(' · ')}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Icon(Icons.edit_rounded,
                                    color: AppTheme.primary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // ── Upgrade Banner (free users) ────────────────────────
                      if (!user.isPremium) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const PremiumPaywallScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF8E2DE2).withValues(alpha: 0.08),
                                  const Color(0xFF4A00E0).withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color:
                                      const Color(0xFF8E2DE2).withValues(alpha: 0.35)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Premium: Smart escalation · 5 contacts · Custom reminders',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8E2DE2),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: Color(0xFF8E2DE2), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),
                      const SizedBox(height: 24),

                      // ── Big Action Buttons ─────────────────────────────────
                      Consumer<ElderProvider>(
                        builder: (context, elderProvider, _) {
                          return Row(
                            children: [
                              // I'm OK
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _ActionButton(
                                    color: AppTheme.primary,
                                    isLoading: elderProvider.isLoading,
                                    onPressed: () => _handleCheckIn(user.uid),
                                    icon: Icons.waving_hand_rounded,
                                    label: "I'M OK",
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // SOS
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _ActionButton(
                                    color: Colors.red.shade700,
                                    isLoading: elderProvider.isLoading,
                                    onPressed: () =>
                                        _confirmEmergency(user.uid),
                                    icon: Icons.warning_rounded,
                                    label: 'SOS',
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────

class _TappableCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color borderColor;
  final Color backgroundColor;

  const _TappableCard({
    required this.onTap,
    required this.child,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final double fontSize;

  const _ActionButton({
    required this.color,
    required this.isLoading,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: EdgeInsets.zero,
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.4),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 44, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Reminder Dialog ──────────────────────────────────────────────────────

class _ReminderDialog extends StatefulWidget {
  final UserModel user;
  final FirestoreService firestoreService;

  const _ReminderDialog(
      {required this.user, required this.firestoreService});

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late List<String> _times;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _times = List<String>.from(widget.user.customCheckInTimes);
  }

  Future<void> _pickTime() async {
    if (_times.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 3 reminders allowed.')));
      return;
    }
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) {
      final formatted = picked.format(context);
      if (!_times.contains(formatted)) {
        setState(() => _times.add(formatted));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.firestoreService
          .saveCustomCheckInTimes(widget.user.uid, _times);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Reminders saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.alarm_rounded, color: AppTheme.primary),
          SizedBox(width: 12),
          Text('Check-in Reminders'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set up to 3 daily times to remind you to check in.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 16),
            if (_times.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.alarm_off_rounded,
                        color: AppTheme.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(width: 10),
                    const Text('No reminders set.',
                        style: TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
              )
            else
              ..._times
                  .map((time) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_rounded,
                            color: AppTheme.primary),
                        title: Text(time,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.statusAlert),
                          onPressed: () =>
                              setState(() => _times.remove(time)),
                        ),
                      )),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Add Reminder Time'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}