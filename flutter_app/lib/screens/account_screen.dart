import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../theme/helping_hand_theme.dart';
import '../widgets/auth_components.dart';

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
    return Theme(
      data: HelpingHandTheme.build().copyWith(
        inputDecorationTheme: AuthStyles.inputTheme,
      ),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: HelpingHandColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final wide = viewport.maxWidth >= 840;
                final gutter = viewport.maxWidth < 360 ? 16.0 : 24.0;
                final brand = AuthBrandHeader(
                  createAccount: _createAccount,
                  wide: wide,
                );
                final form = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildForm(context),
                );
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: wide
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1040,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(child: brand),
                                    const SizedBox(width: 64),
                                    Expanded(child: form),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              brand,
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  gutter,
                                  _createAccount ? 32 : 16,
                                  gutter,
                                  32,
                                ),
                                child: Center(child: form),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final linkingAnonymous =
        widget.authService.currentUser?.isAnonymous == true;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                _createAccount ? 'Create your account' : 'Welcome back',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _createAccount
                  ? 'Save your progress. Find your rhythm.'
                  : 'Sign in to continue your ASL practice.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (linkingAnonymous) ...[
              const AuthNotice(
                message: 'Create an account to keep progress from this device.',
                icon: Icons.cloud_done_outlined,
              ),
              const SizedBox(height: 24),
            ],
            TextFormField(
              key: ValueKey('email-$_createAccount'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (value) {
                final email = value?.trim() ?? '';
                return email.contains('@')
                    ? null
                    : 'Enter a valid email address.';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey('password-$_createAccount'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: _createAccount
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: _createAccount ? null : (_) => _submit(),
              autofillHints: _createAccount
                  ? const [AutofillHints.newPassword]
                  : const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: _createAccount
                    ? 'Use at least 6 characters.'
                    : null,
                helperMaxLines: 3,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (value) => value == _passwordController.text
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
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),

            if (_message != null) ...[
              const SizedBox(height: 16),
              AuthNotice(
                message: _message!,
                success: _showSuccessMessage,
                error: !_showSuccessMessage,
                icon: _showSuccessMessage
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? Semantics(
                      label: 'Please wait',
                      child: const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: HelpingHandColors.textSecondary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _createAccount ? 'Create account' : 'Sign in',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  _createAccount
                      ? 'Already have an account?'
                      : 'New to Helping Hand?',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: _busy ? null : () => _switchMode(!_createAccount),
                  child: Text(
                    _createAccount ? 'Sign in' : 'Create account',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
