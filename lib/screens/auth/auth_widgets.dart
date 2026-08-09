import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';

/// Pieces shared by the sign-in and sign-up screens so the two stay visually
/// identical without duplicating layout code.

/// Gradient header with the brand mark and tagline.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.height,
    this.tagline = 'Real-time translation for text, voice, and images',
  });

  final double height;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 76, showShadow: false),
            const SizedBox(height: AppSpacing.md),
            const BrandWordmark(color: Colors.white, fontSize: 28),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                tagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rounded surface panel the auth forms sit on.
class AuthSheet extends StatelessWidget {
  const AuthSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg,
      ),
      child: child,
    );
  }
}

/// Small caption above a text field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Horizontal rule with centered caption.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or continue with'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Google's "G" drawn locally so the prototype needs no network image.
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADCE0)),
        color: Colors.white,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
          height: 1.1,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- validators

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  final valid = RegExp(r'^[\w.\-+]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v);
  if (!valid) return 'Enter a valid email address';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validateName(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Full name is required';
  if (v.length < 2) return 'Enter your full name';
  return null;
}

/// Rough password strength on a 0–1 scale, plus a label and color for the meter.
({double score, String label, Color color}) passwordStrength(String value) {
  if (value.isEmpty) {
    return (score: 0, label: '', color: Colors.grey);
  }
  var points = 0;
  if (value.length >= 6) points++;
  if (value.length >= 10) points++;
  if (RegExp(r'[A-Z]').hasMatch(value)) points++;
  if (RegExp(r'\d').hasMatch(value)) points++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) points++;

  if (points <= 2) {
    return (score: 0.33, label: 'Weak', color: AppColors.danger);
  }
  if (points <= 3) {
    return (score: 0.66, label: 'Fair', color: const Color(0xFFF59E0B));
  }
  return (score: 1, label: 'Strong', color: AppColors.accent);
}
