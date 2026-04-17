import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/theme.dart';
import '../premium_paywall_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isUpdatingName = false;
  bool _isUpdatingPassword = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppAuthProvider>(context, listen: false).userModel;
    _nameController.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.statusAlert : null,
    ));
  }

  Future<void> _updateDisplayName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Name cannot be empty.', isError: true);
      return;
    }
    setState(() => _isUpdatingName = true);
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      await authProvider.updateDisplayName(name);
      _showSnack('Name updated successfully!');
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isUpdatingName = false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    if (current.isEmpty || newPass.isEmpty) {
      _showSnack('Please fill in both password fields.', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnack('New password must be at least 6 characters.', isError: true);
      return;
    }
    setState(() => _isUpdatingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Re-authenticate first (required by Firebase before sensitive operations)
      final credential = EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _showSnack('Password changed successfully!');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Failed to change password.', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // Step 1: Ask for confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all your data. This action CANNOT be undone.\n\nAre you absolutely sure?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Step 2: Ask for password to re-authenticate before deleting
    final passwordController = TextEditingController();
    final reauthed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Your Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your current password to confirm account deletion.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (reauthed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      await authProvider.deleteAccount(passwordController.text.trim());
      // authProvider.signOut() is called inside deleteAccount, navigation handled by RoleChecker
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
        setState(() => _isDeletingAccount = false);
      }
    }
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().userModel;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Banner (if not premium)
              if (user != null && !user.isPremium) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Upgrade to Premium", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(height: 4),
                            Text("Unlock smart escalation & multiple contacts.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A00E0),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()),
                          );
                        },
                        child: const Text("View"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              if (user != null && user.isPremium) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 28),
                      const SizedBox(width: 12),
                      const Text("Premium Subscribed", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Account Info
              _SectionHeader(icon: Icons.person_rounded, title: 'Profile'),
              const SizedBox(height: 16),
              Text('Email: ${user?.email ?? ''}', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                labelText: 'Display Name',
                hintText: 'Enter your name',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Update Name',
                onPressed: _updateDisplayName,
                isLoading: _isUpdatingName,
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Change Password
              _SectionHeader(icon: Icons.lock_reset_rounded, title: 'Change Password'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _currentPasswordController,
                labelText: 'Current Password',
                hintText: 'Enter your current password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _newPasswordController,
                labelText: 'New Password',
                hintText: 'At least 6 characters',
                prefixIcon: Icons.lock_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Change Password',
                onPressed: _changePassword,
                isLoading: _isUpdatingPassword,
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Danger Zone
              _SectionHeader(icon: Icons.warning_rounded, title: 'Danger Zone', color: AppTheme.statusAlert),
              const SizedBox(height: 8),
              Text(
                'Deleting your account is permanent and cannot be undone. All your data will be erased.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              _isDeletingAccount
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusAlert,
                        side: const BorderSide(color: AppTheme.statusAlert, width: 2),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete My Account'),
                      onPressed: _confirmDeleteAccount,
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
