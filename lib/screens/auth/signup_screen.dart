import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _selectedRole = AppConstants.roleElder;
  bool _startPremium = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> signupUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please enter all fields.');
      return;
    }

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await authProvider.signup(email, password, _selectedRole, name, startPremium: _startPremium);
      if (!mounted) return;
      Navigator.pop(context); // Go back to login/home
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

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Join SoulPing Care', textAlign: TextAlign.center, style: theme.textTheme.displayMedium),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: nameController,
                        labelText: 'Full Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: passwordController,
                        labelText: 'Password',
                        hintText: 'Create a password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      const Text('I am a:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: AppConstants.roleElder, label: Text('Elder')),
                          ButtonSegment(value: AppConstants.roleContact, label: Text('Trusted Contact')),
                        ],
                        selected: <String>{_selectedRole},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedRole = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: CheckboxListTile(
                          title: const Text('Start with Premium (\$2.99/mo)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Unlock multiple contacts and smart escalation alerts.'),
                          value: _startPremium,
                          activeColor: Colors.amber.shade700,
                          onChanged: (val) {
                            setState(() {
                              _startPremium = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Sign Up',
                        onPressed: signupUser,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}