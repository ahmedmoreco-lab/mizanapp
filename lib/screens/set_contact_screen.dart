import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/elder_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/theme.dart';
import 'premium_paywall_screen.dart';

class SetContactScreen extends StatefulWidget {
  const SetContactScreen({super.key});

  @override
  State<SetContactScreen> createState() => _SetContactScreenState();
}

class _SetContactScreenState extends State<SetContactScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _linkedContacts = [];
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final user = Provider.of<AppAuthProvider>(context, listen: false).userModel;
    if (user == null || user.trustedContacts.isEmpty) {
      if (mounted) setState(() { _linkedContacts = []; _isLoadingContacts = false; });
      return;
    }
    
    try {
      final contacts = await _firestoreService.getContactsByIds(user.trustedContacts);
      if (mounted) {
        setState(() {
          _linkedContacts = contacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

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
    final user = authProvider.userModel;
    
    if (user == null) return;

    try {
      await Provider.of<ElderProvider>(context, listen: false).linkContact(user.uid, email);
      _showMessage('Trusted Contact Linked Successfully!');
      _emailController.clear();
      // the userModel updates via authProvider stream, but let's refresh list
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadContacts();
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _deleteContact(String contactId) async {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final elderUid = authProvider.userModel?.uid;
    if (elderUid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Contact"),
        content: const Text("Are you sure you want to remove this trusted contact?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusAlert, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Remove")
          ),
        ],
      )
    );

    if (confirm != true) return;

    try {
      await Provider.of<ElderProvider>(context, listen: false).removeContact(elderUid, contactId);
      _showMessage('Contact removed');
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadContacts();
    } catch(e) {
      _showMessage("Error removing contact: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingBase = context.watch<ElderProvider>().isLoading;
    final user = context.watch<AppAuthProvider>().userModel;
    
    final maxContacts = (user?.isPremium ?? false) ? 5 : 3;
    final contactCount = user?.trustedContacts.length ?? 0;
    final canAddMore = contactCount < maxContacts;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Contacts')),
      body: SafeArea(
        child: _isLoadingContacts 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Trusted Contacts ($contactCount/$maxContacts)',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'These contacts will be notified in an emergency.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  if (_linkedContacts.isNotEmpty) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _linkedContacts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final contact = _linkedContacts[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.statusNeutral.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.person, color: AppTheme.primary),
                            ),
                            title: Text(contact.name ?? contact.email.split('@')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(contact.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.statusAlert),
                              onPressed: () => _deleteContact(contact.uid),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (canAddMore) ...[
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      'Add New Contact',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      labelText: "Contact Email",
                      hintText: "e.g. child@example.com",
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: "Add Contact",
                      onPressed: _linkContact,
                      isLoading: isLoadingBase,
                    ),
                  ] else if (!(user?.isPremium ?? false)) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            "Upgrade to add up to 5 contacts and unlock smart escalation.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            text: "Upgrade to Premium",
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen())),
                          )
                        ],
                      ),
                    )
                  ],
                ],
              ),
            ),
      ),
    );
  }
}