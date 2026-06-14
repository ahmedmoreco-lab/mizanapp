import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
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
    final l = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l.accountSettings)),
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
                          children: [
                            Text(l.upgradeToP, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(l.unlockPremium, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                        child: Text(l.view),
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
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(l.premiumSubbed, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Language
              _SectionHeader(icon: Icons.language_rounded, title: l.language),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LangButton(
                      label: l.english,
                      flag: '🇬🇧',
                      selected: localeProvider.locale.languageCode == 'en',
                      onTap: () => localeProvider.setLocale(const Locale('en')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LangButton(
                      label: l.arabic,
                      flag: '🇸🇦',
                      selected: localeProvider.locale.languageCode == 'ar',
                      onTap: () => localeProvider.setLocale(const Locale('ar')),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Account Info
              _SectionHeader(icon: Icons.person_rounded, title: l.profile),
              const SizedBox(height: 16),
              Text('Email: ${user?.email ?? ''}', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                labelText: l.displayName,
                hintText: l.enterName,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: l.updateName,
                onPressed: _updateDisplayName,
                isLoading: _isUpdatingName,
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Change Password
              _SectionHeader(icon: Icons.lock_reset_rounded, title: l.changePassword),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _currentPasswordController,
                labelText: l.currentPassword,
                hintText: l.enterCurrentPassword,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _newPasswordController,
                labelText: l.newPassword,
                hintText: l.atLeast6Chars,
                prefixIcon: Icons.lock_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: l.changePassword,
                onPressed: _changePassword,
                isLoading: _isUpdatingPassword,
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Danger Zone
              _SectionHeader(icon: Icons.warning_rounded, title: l.dangerZone, color: AppTheme.statusAlert),
              const SizedBox(height: 8),
              Text(
                l.deleteAccountWarning,
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
                      label: Text(l.deleteAccount),
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

class _LangButton extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: AppTheme.primary),
            ],
          ],
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
