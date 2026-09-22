import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/language_model.dart';
import '../services/language_service.dart';
import '../services/starter_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';
import '../widgets/language_card.dart';
import '../widgets/state_views.dart';
import 'language_form_screen.dart';
import 'lesson_management_screen.dart';

/// READ + entry point for language CRUD.
///
/// Lists every language from Firestore as a live stream, with search, an
/// "Add Language" action, and per-row Edit/Delete. Tapping a card drills into
/// that language's lessons.
class LanguageManagementScreen extends StatefulWidget {
  const LanguageManagementScreen({super.key});

  @override
  State<LanguageManagementScreen> createState() =>
      _LanguageManagementScreenState();
}

class _LanguageManagementScreenState extends State<LanguageManagementScreen> {
  final _service = LanguageService();
  final _searchController = TextEditingController();
  String _query = '';
  bool _importing = false;

  Future<void> _importStarterContent() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final count = await StarterContentService().importAll();
      if (!mounted) return;
      showSnack(
        context,
        count == 0
            ? 'Starter lessons are already imported.'
            : '$count starter lessons imported. You can now edit them.',
      );
    } catch (_) {
      if (!mounted) return;
      showSnack(
        context,
        'Could not import lessons. Check your connection and content-editing access, then retry.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LanguageModel> _applySearch(List<LanguageModel> languages) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return languages;
    return languages
        .where(
          (l) =>
              l.name.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _openForm([LanguageModel? existing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LanguageFormScreen(existing: existing)),
    );
  }

  void _openLessons(LanguageModel language) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonManagementScreen(language: language),
      ),
    );
  }

  Future<void> _confirmDelete(LanguageModel language) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this language?',
      message:
          'Are you sure you want to delete "${language.name}"? Its lessons '
          'will be permanently removed too. This cannot be undone.',
    );
    if (!ok || !mounted) return;

    try {
      await _service.deleteLanguage(language.id);
      if (!mounted) return;
      showSnack(context, '"${language.name}" deleted');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Delete failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard against the app running before `flutterfire configure` was run.
    if (Firebase.apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Language Management')),
        body: const FirebaseNotReadyView(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Language Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Language'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: OutlinedButton.icon(
              onPressed: _importing ? null : _importStarterContent,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline_outlined),
              label: Text(
                _importing
                    ? 'Importing starter lessons…'
                    : 'Import starter lessons for editing',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search languages',
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
          Expanded(
            child: StreamBuilder<List<LanguageModel>>(
              stream: _service.getLanguages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorView(message: '${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }

                final all = snapshot.data ?? const [];
                if (all.isEmpty) {
                  return EmptyView(
                    icon: Icons.translate_rounded,
                    title: 'No languages yet',
                    message:
                        'Add your first language module to get started. '
                        'For example: Cebuano, Ilocano, or Kapampangan.',
                    actionLabel: 'Add Language',
                    onAction: () => _openForm(),
                  );
                }

                final languages = _applySearch(all);
                if (languages.isEmpty) {
                  return MessageView(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'No languages match "$_query".',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    96,
                  ),
                  itemCount: languages.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final language = languages[i];
                    return LanguageCard(
                      language: language,
                      onTap: () => _openLessons(language),
                      onEdit: () => _openForm(language),
                      onDelete: () => _confirmDelete(language),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
