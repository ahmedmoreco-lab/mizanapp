import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/theme.dart';
import 'auth/forgot_password_screen.dart';
import 'auth/verify_email_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(l.loginError),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  bool _isLoading = false;

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await authProvider.login(email, password);
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        // Signed in but not verified — send them to the verify screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
          (route) => false,
        );
        return;
      }

      // Clear the entire back stack and go to home — RoleChecker will
      // pick the correct screen (Elder or Contact) based on the user's role.
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.locale.languageCode == 'ar';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Language toggle — top right corner
            Positioned(
              top: 8,
              right: 8,
              child: TextButton.icon(
                onPressed: () => localeProvider.setLocale(
                  isArabic ? const Locale('en') : const Locale('ar'),
                ),
                icon: Text(isArabic ? '🇬🇧' : '🇸🇦', style: const TextStyle(fontSize: 18)),
                label: Text(
                  isArabic ? 'English' : 'عربي',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          CircleAvatar(
                        radius: 46,
                        backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                        child: const Icon(Icons.favorite_rounded, size: 46, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(l.appTitle, style: theme.textTheme.displayMedium),
                      const SizedBox(height: 12),
                      Text(
                        l.welcomeBack,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        controller: emailController,
                        labelText: l.email,
                        hintText: l.enterEmail,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: passwordController,
                        labelText: l.password,
                        hintText: l.enterPassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: l.signIn,
                        onPressed: loginUser,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: Text(l.forgotPassword, style: const TextStyle(fontSize: 15, color: AppTheme.textMuted)),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: Text(l.needAccount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
