import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<AppAuthProvider>(context, listen: false).sendPasswordReset(email);
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _emailSent ? _buildSuccessState(theme) : _buildFormState(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: const Icon(Icons.lock_reset_rounded, size: 40, color: AppTheme.primary),
        ),
        const SizedBox(height: 24),
        Text('Forgot Password?', textAlign: TextAlign.center, style: theme.textTheme.displayMedium),
        const SizedBox(height: 12),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Send Reset Link',
          onPressed: _sendReset,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.mark_email_read_rounded, size: 40, color: AppTheme.statusSafe),
        ),
        const SizedBox(height: 24),
        Text('Check Your Inbox', textAlign: TextAlign.center, style: theme.textTheme.displayMedium),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to:\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Back to Login',
          onPressed: () => Navigator.pop(context),
          isLoading: false,
        ),
      ],
    );
  }
}
