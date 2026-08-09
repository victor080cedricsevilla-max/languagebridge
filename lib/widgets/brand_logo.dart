import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Language Bridge mark: a gradient tile with a translate glyph.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
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
      child: Icon(
        Icons.g_translate_rounded,
        color: Colors.white,
        size: size * 0.5,
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
