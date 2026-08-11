import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'signup_screen.dart';

/// Sign-in screen.
///
/// [_submit] runs Firebase Auth's email/password sign-in. On success the auth
/// gate in `main.dart` swaps the root to the app shell, so this screen does not
/// navigate itself.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await AppScope.read(context).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Success: the auth gate rebuilds to the app shell and disposes us.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _snack(authErrorMessage(e));
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (validateEmail(email) != null) {
      _snack('Enter your email above first, then tap "Forgot password?"');
      return;
    }
    try {
      await AppScope.read(context).sendPasswordReset(email);
      if (!mounted) return;
      _snack('Password reset email sent to $email');
    } catch (e) {
      if (!mounted) return;
      _snack(authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final heroHeight = (size.height * 0.34).clamp(220.0, 320.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.paddingOf(context).top,
              ),
              child: Column(
                children: [
                  AuthHero(height: heroHeight),
                  AuthSheet(child: _buildForm(theme)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue breaking language barriers.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const FieldLabel('Email'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),

          const FieldLabel('Password'),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            validator: validatePassword,
          ),
          const SizedBox(height: AppSpacing.xs),

          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  'Remember me',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: _isSubmitting ? null : _forgotPassword,
                child: const Text(
                  'Forgot password?',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign In'),
          ),
          const SizedBox(height: AppSpacing.lg),

          const OrDivider(),
          const SizedBox(height: AppSpacing.lg),

          OutlinedButton.icon(
            onPressed: () => _snack('Google Sign-In is not available in this build'),
            icon: const GoogleGlyph(),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "Don't have an account?",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text('Sign Up'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
