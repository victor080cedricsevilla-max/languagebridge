import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/language.dart';
import '../theme/app_theme.dart';

/// Bottom sheet for choosing a language. Returns the selected code, or null
/// if dismissed.
Future<String?> showLanguagePicker(
  BuildContext context, {
  required String selectedCode,
  required String title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _LanguagePickerSheet(
      selectedCode: selectedCode,
      title: title,
    ),
  );
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet({required this.selectedCode, required this.title});

  final String selectedCode;
  final String title;

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Language> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kLanguages;
    return kLanguages
        .where((l) =>
            l.name.toLowerCase().contains(q) ||
            l.nativeName.toLowerCase().contains(q) ||
            l.code.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search languages',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No languages match "$_query"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final lang = results[i];
                        final selected = lang.code == widget.selectedCode;
                        return ListTile(
                          onTap: () => Navigator.pop(context, lang.code),
                          leading: Text(
                            lang.flag,
                            style: const TextStyle(fontSize: 26),
                          ),
                          title: Text(
                            lang.name,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: lang.nativeName == lang.name
                              ? null
                              : Text(lang.nativeName),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.brand,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The From / To row with a swap button between the two pills.
class LanguageSwapBar extends StatelessWidget {
  const LanguageSwapBar({
    super.key,
    required this.sourceCode,
    required this.targetCode,
    required this.onSourceTap,
    required this.onTargetTap,
    required this.onSwap,
    this.onLight = false,
  });

  final String sourceCode;
  final String targetCode;
  final VoidCallback onSourceTap;
  final VoidCallback onTargetTap;
  final VoidCallback onSwap;

  /// True when the bar sits on the brand gradient instead of a surface.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LanguagePill(
            code: sourceCode,
            label: 'From',
            onTap: onSourceTap,
            onLight: onLight,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Material(
            color: onLight
                ? Colors.white.withValues(alpha: 0.22)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSwap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 22,
                  color: onLight
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _LanguagePill(
            code: targetCode,
            label: 'To',
            onTap: onTargetTap,
            onLight: onLight,
          ),
        ),
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.code,
    required this.label,
    required this.onTap,
    required this.onLight,
  });

  final String code;
  final String label;
  final VoidCallback onTap;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = languageByCode(code);
    final foreground = onLight ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: onLight
          ? Colors.white.withValues(alpha: 0.16)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(lang.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lang.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: foreground.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
