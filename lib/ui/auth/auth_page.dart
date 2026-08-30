import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.auth});

  final FirebaseAuth auth;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _createAccount = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.x24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Ahmed OS',
                          style: AppType.screenTitle.copyWith(color: t.ink)),
                      const SizedBox(height: Sp.x6),
                      Text('Your goals, training and daily focus.',
                          style: AppType.body.copyWith(color: t.muted)),
                      const SizedBox(height: Sp.x24),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Sign in')),
                          ButtonSegment(
                              value: true, label: Text('Create account')),
                        ],
                        selected: {_createAccount},
                        onSelectionChanged: _submitting
                            ? null
                            : (selection) => setState(() {
                                  _createAccount = selection.first;
                                  _error = null;
                                }),
                      ),
                      const SizedBox(height: Sp.x20),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sp.x10),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_submitting,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: _createAccount
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Use at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: Sp.x10),
                        Text(_error!,
                            style: AppType.meta.copyWith(color: t.danger)),
                      ],
                      const SizedBox(height: Sp.x14),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.btnInk,
                                  ),
                                )
                              : Text(_createAccount
                                  ? 'Create account'
                                  : 'Sign in'),
                        ),
                      ),
                      if (!_createAccount) ...[
                        const SizedBox(height: Sp.x8),
                        TextButton(
                          onPressed: _submitting ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ],
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

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_createAccount) {
        await widget.auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await widget.auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error.code));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email address first');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error.code));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(String code) => switch (code) {
        'email-already-in-use' => 'An account already uses this email',
        'weak-password' => 'Use a stronger password',
        'invalid-email' => 'Enter a valid email address',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' =>
          'Email or password is incorrect',
        'user-disabled' => 'This account has been disabled',
        'too-many-requests' => 'Too many attempts. Try again later',
        'network-request-failed' => 'Check your internet connection',
        _ => 'Could not complete that request',
      };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
