import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Language Bridge mark: the app icon (a bridge on an indigo-to-teal
/// gradient) as a rounded tile, matching the launcher icon.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.24);
    return Semantics(
      label: 'Language Bridge logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.35),
                    blurRadius: size * 0.35,
                    offset: Offset(0, size * 0.14),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(
            'assets/branding/icon.png',
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

/// Wordmark used under the logo on the auth screens.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.color, this.fontSize = 26});

  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.onSurface;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: base,
        ),
        children: [
          const TextSpan(text: 'Language '),
          TextSpan(
            text: 'Bridge',
            style: TextStyle(color: base.withValues(alpha: 0.62)),
          ),
        ],
      ),
    );
  }
}
