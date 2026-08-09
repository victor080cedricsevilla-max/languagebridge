import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/translation_record.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

/// Filters available above the history list.
enum _HistoryFilter {
  all('All', null),
  favorites('Favorites', null),
  text('Text', TranslationSource.text),
  voice('Voice', TranslationSource.voice),
  camera('Camera', TranslationSource.camera);

  const _HistoryFilter(this.label, this.source);
  final String label;
  final TranslationSource? source;
}

/// Translation history with search, filtering, swipe-to-delete and undo.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TranslationRecord> _applyFilters(List<TranslationRecord> records) {
    return records.where((r) {
      if (!r.matches(_query)) return false;
      return switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.favorites => r.isFavorite,
        _ => r.source == _filter.source,
      };
    }).toList();
  }

  /// Interleaves date headers into the record list for a single flat ListView.
  List<Object> _withHeaders(List<TranslationRecord> records) {
    final items = <Object>[];
    String? lastLabel;
    for (final record in records) {
      final label = DateFormats.groupLabel(record.createdAt);
      if (label != lastLabel) {
        items.add(label);
        lastLabel = label;
      }
      items.add(record);
    }
    return items;
  }

  void _deleteWithUndo(TranslationRecord record) {
    final state = AppScope.read(context);
    final index = state.indexOfRecord(record.id);
    state.deleteRecord(record.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Translation deleted'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.accent,
            onPressed: () => state.restoreRecord(record, index),
          ),
        ),
      );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This removes every saved translation, including favorites. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    AppScope.read(context).clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final filtered = _applyFilters(state.history);
    final items = _withHeaders(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (state.history.isNotEmpty)
            IconButton(
              onPressed: _confirmClearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search translations',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _HistoryFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final option = _HistoryFilter.values[i];
                return FilterChip(
                  label: Text(option.label),
                  selected: _filter == option,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = option),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: items.isEmpty
                ? _EmptyState(
                    hasHistory: state.history.isNotEmpty,
                    query: _query,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item is String) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : AppSpacing.md,
                            bottom: AppSpacing.sm,
                            left: 4,
                          ),
                          child: Text(
                            item,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.3,
                            ),
                          ),
                        );
                      }

                      final record = item as TranslationRecord;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Dismissible(
                          key: ValueKey(record.id),
                          direction: DismissDirection.endToStart,
                          background: _DismissBackground(),
                          onDismissed: (_) => _deleteWithUndo(record),
                          child: _HistoryTile(
                            record: record,
                            onFavorite: () => state.toggleFavorite(record.id),
                            onTap: () => _showDetail(record),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(TranslationRecord record) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _DetailSheet(record: record),
    );
  }
}

// -------------------------------------------------------------------- tile

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.record,
    required this.onFavorite,
    required this.onTap,
  });

  final TranslationRecord record;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  static const _sourceIcons = {
    TranslationSource.text: Icons.text_fields_rounded,
    TranslationSource.voice: Icons.mic_rounded,
    TranslationSource.camera: Icons.photo_camera_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = languageByCode(record.sourceLangCode);
    final to = languageByCode(record.targetLangCode);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${from.flag} ${from.code.toUpperCase()}'
                      '  →  '
                      '${to.flag} ${to.code.toUpperCase()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    _sourceIcons[record.source],
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Text(
                    DateFormats.relative(record.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                record.sourceText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      record.translatedText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkResponse(
                    onTap: onFavorite,
                    radius: 22,
                    child: Icon(
                      record.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 22,
                      color: record.isFavorite
                          ? const Color(0xFFF59E0B)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
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

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}

// ------------------------------------------------------------ detail sheet

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.record});
  final TranslationRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = languageByCode(record.sourceLangCode);
    final to = languageByCode(record.targetLangCode);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormats.longDate(record.createdAt),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailBlock(
            language: '${from.flag}  ${from.name}',
            text: record.sourceText,
            emphasized: false,
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailBlock(
            language: '${to.flag}  ${to.name}',
            text: record.translatedText,
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: record.translatedText),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    AppScope.read(context).toggleFavorite(record.id);
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    record.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                  ),
                  label: Text(record.isFavorite ? 'Unsave' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.language,
    required this.text,
    required this.emphasized,
  });

  final String language;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.accent.withValues(alpha: 0.10)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: emphasized
                ? theme.textTheme.titleLarge?.copyWith(height: 1.35)
                : theme.textTheme.titleMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- empty state

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasHistory, required this.query});

  /// True when records exist but the current search/filter hides them all.
  final bool hasHistory;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtering = hasHistory;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                filtering
                    ? Icons.search_off_rounded
                    : Icons.history_toggle_off_rounded,
                size: 40,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              filtering ? 'No matches' : 'No translations yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              filtering
                  ? (query.isEmpty
                      ? 'Nothing matches this filter.'
                      : 'Nothing matches "$query".')
                  : 'Your translations will appear here once you start '
                      'using the Translate tab.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
