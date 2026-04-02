import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/elder_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/theme.dart';

class SetContactScreen extends StatefulWidget {
  const SetContactScreen({super.key});

  @override
  State<SetContactScreen> createState() => _SetContactScreenState();
}

class _SetContactScreenState extends State<SetContactScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _linkContact() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter an email");
      return;
    }

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final elderUid = authProvider.userModel?.uid;
    
    if (elderUid == null) return;

    try {
      await Provider.of<ElderProvider>(context, listen: false).linkContact(elderUid, email);
      _showMessage('Trusted Contact Linked Successfully!');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ElderProvider>().isLoading;
    final user = context.watch<AppAuthProvider>().userModel;
    final hasContact = user?.trustedContactId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Contact')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Link a Trusted Contact',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the email address of the person who will be notified about your safety status.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              
              if (hasContact)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSafe.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.statusSafe),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppTheme.statusSafe),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You already have a linked contact. Linking a new one will replace the current one.",
                          style: TextStyle(color: AppTheme.statusSafe, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              CustomTextField(
                controller: _emailController,
                labelText: "Contact Email",
                hintText: "e.g. child@example.com",
                prefixIcon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: hasContact ? "Update Contact" : "Link Contact",
                onPressed: _linkContact,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}