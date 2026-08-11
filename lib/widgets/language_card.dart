import 'package:flutter/material.dart';

import '../models/language_model.dart';
import '../theme/app_theme.dart';

/// Card row for one language in the management list.
///
/// Tapping the body opens the language's lessons; the footer holds the Edit
/// and Delete actions.
class LanguageCard extends StatelessWidget {
  const LanguageCard({
    super.key,
    required this.language,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final LanguageModel language;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _LanguageAvatar(language: language),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                language.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _StatusBadge(isActive: language.isActive),
                          ],
                        ),
                        if (language.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            language.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              Container(width: 1, height: 24, color: theme.dividerColor),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular avatar: the network image when a valid URL is provided, otherwise
/// the language's first letter on a brand-tinted background.
class _LanguageAvatar extends StatelessWidget {
  const _LanguageAvatar({required this.language});

  final LanguageModel language;

  @override
  Widget build(BuildContext context) {
    final initial =
        language.name.isNotEmpty ? language.name[0].toUpperCase() : '?';
    final hasImage = language.imageUrl.trim().startsWith('http');

    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: hasImage
          ? Image.network(
              language.imageUrl,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              // Fall back to the initial if the image fails to load.
              errorBuilder: (_, __, ___) => _Initial(initial: initial),
            )
          : _Initial(initial: initial),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: const TextStyle(
        color: AppColors.brand,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Small pill showing whether the language is active or inactive.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : Theme.of(context).disabledColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
