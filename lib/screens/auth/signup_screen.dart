import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'elder';
  String? _selectedGender;
  bool _isPremium = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const _genders = ['Male', 'Female', 'Other'];

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'firstName': firstName,
        'lastName': lastName,
        'name': '$firstName $lastName',
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'isPremium': _isPremium,
        'createdAt': FieldValue.serverTimestamp(),
        'trustedContacts': [],
        'escalationOrder': [],
        'customCheckInTimes': [],
        'inactivityThresholdHours': 24,
      });

      // Send verification email before letting the user in
      await credential.user!.sendEmailVerification();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Signup failed');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.createAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.signUp, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(l.fillDetails, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 28),

                // — Name row —
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _firstNameController,
                        label: l.firstName,
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        controller: _lastNameController,
                        label: l.lastName,
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // — Age —
                _Field(
                  controller: _ageController,
                  label: l.age,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l.required;
                    final age = int.tryParse(v.trim());
                    if (age == null || age < 1 || age > 120) return l.enterValidAge;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // — Gender —
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(labelText: l.gender),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                  validator: (v) => v == null ? l.selectGender : null,
                ),
                const SizedBox(height: 16),

                // — Email —
                _Field(
                  controller: _emailController,
                  label: l.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l.required;
                    if (!v.contains('@')) return l.enterValidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // — Password —
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l.password,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.required;
                    if (v.length < 6) return l.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // — Role —
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(labelText: l.role),
                  items: [
                    DropdownMenuItem(value: 'elder', child: Text(l.elderRole)),
                    DropdownMenuItem(value: 'contact', child: Text(l.trustedContactRole)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedRole = v);
                  },
                ),
                const SizedBox(height: 24),

                // — Premium option —
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isPremium ? const Color(0xFF123247) : Colors.grey.shade300,
                      width: _isPremium ? 2 : 1,
                    ),
                    color: _isPremium
                        ? const Color(0xFF123247).withValues(alpha: 0.05)
                        : Colors.transparent,
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(l.startWithPremium, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    subtitle: Text(l.premiumSubtitle, style: const TextStyle(fontSize: 13)),
                    secondary: const Icon(Icons.star_rounded, color: Color(0xFFE0B14C)),
                    value: _isPremium,
                    activeColor: const Color(0xFF123247),
                    onChanged: (v) => setState(() => _isPremium = v),
                  ),
                ),
                const SizedBox(height: 32),

                // — Submit —
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signUp,
                          child: Text(l.createAccount),
                        ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.haveAccount),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }
}
