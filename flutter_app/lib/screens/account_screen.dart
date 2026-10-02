import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../theme/warm_clay_theme.dart';
import '../widgets/warm_components.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.authService});

  final FirebaseAuthService authService;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _createAccount = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _message;
  bool _showSuccessMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(bool createAccount) {
    setState(() {
      _createAccount = createAccount;
      _message = null;
      _showSuccessMessage = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
      _showSuccessMessage = false;
    });

    try {
      if (_createAccount) {
        await widget.authService.createAccount(
          displayName: '',
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await widget.authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _message = _friendlyMessage(error));
    } on Object {
      if (!mounted) return;
      setState(
        () => _message =
            'We could not complete that request. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _message = 'Enter your email address first.';
        _showSuccessMessage = false;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _showSuccessMessage = false;
    });
    try {
      await widget.authService.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          _message =
              'If an account uses that email, a password reset link is on its way.';
          _showSuccessMessage = true;
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _friendlyMessage(error));
      }
    } on Object {
      if (mounted) {
        setState(() => _message = 'Could not send the reset email. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' || 'credential-already-in-use' =>
        'An account already uses that email. Sign in instead.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Choose a password with at least 6 characters.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email or password is incorrect.',
      'too-many-requests' => 'Too many attempts. Wait a bit and try again.',
      'network-request-failed' =>
        'You appear to be offline. Check your connection.',
      'operation-not-allowed' =>
        'Email and password sign-in is not enabled for this Firebase project yet.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final linkingAnonymous =
        widget.authService.currentUser?.isAnonymous == true;
    final theme = Theme.of(context);
    final heading = _createAccount ? 'Create your account' : 'Welcome back';
    final description = _createAccount
        ? 'Save your learning progress and pick up anytime.'
        : 'Sign in to continue your ASL practice.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: WarmClayTheme.screenPadding.copyWith(bottom: 62),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/hh-logo.png',
                      width: 128,
                      height: 128,
                      fit: BoxFit.contain,
                      semanticLabel: 'Helping Hand logo',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Helping Hand',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ASL practice, one sign at a time.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: WarmClayColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (linkingAnonymous)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WarmClayColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.cloud_done_outlined,
                              color: WarmClayColors.accentPrimary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Create an account to keep progress from this device.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  WarmCard(
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              heading,
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: WarmClayColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                return email.contains('@')
                                    ? null
                                    : 'Enter a valid email address.';
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: _createAccount
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted: _createAccount
                                  ? null
                                  : (_) => _submit(),
                              autofillHints: _createAccount
                                  ? const [AutofillHints.newPassword]
                                  : const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.isEmpty) {
                                  return 'Enter a password.';
                                }
                                if (_createAccount && password.length < 6) {
                                  return 'Use at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            if (_createAccount) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                ),
                                validator: (value) =>
                                    value == _passwordController.text
                                    ? null
                                    : 'Passwords do not match.',
                              ),
                            ],
                            if (!_createAccount)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy ? null : _sendPasswordReset,
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            if (_message != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _showSuccessMessage
                                      ? const Color(0xFF3C8C62)
                                      : theme.colorScheme.error,
                                ),
                              ),
                            ],
                            SizedBox(height: _createAccount ? 18 : 4),
                            SizedBox(
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _createAccount
                                      ? WarmClayColors.accentPrimary
                                      : null,
                                  gradient: _createAccount
                                      ? null
                                      : const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFF4B7964),
                                            WarmClayColors.accentPrimary,
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white70,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: _busy
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _createAccount
                                              ? 'Create account'
                                              : 'Sign in',
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Color(0xFFD7DCD7)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9AA29C),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: Color(0xFFD7DCD7)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _createAccount
                                      ? 'Already have an account?'
                                      : 'New to Helping Hand?',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _switchMode(!_createAccount),
                                  child: Text(
                                    _createAccount
                                        ? 'Sign in'
                                        : 'Create account',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_createAccount)
                    Text(
                      'Use at least 6 characters for your password.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
