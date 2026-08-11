import 'package:flutter/material.dart';

import '../models/language_model.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';
import '../widgets/lesson_card.dart';
import '../widgets/state_views.dart';
import 'lesson_form_screen.dart';

/// READ + entry point for lesson CRUD, scoped to one language.
///
/// Streams the lessons whose `languageId` matches [language], with an
/// "Add Lesson" action and per-row Edit/Delete.
class LessonManagementScreen extends StatefulWidget {
  const LessonManagementScreen({super.key, required this.language});

  final LanguageModel language;

  @override
  State<LessonManagementScreen> createState() => _LessonManagementScreenState();
}

class _LessonManagementScreenState extends State<LessonManagementScreen> {
  final _service = LessonService();

  LanguageModel get _language => widget.language;

  Future<void> _openForm([Lesson? existing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonFormScreen(
          languageId: _language.id,
          languageName: _language.name,
          existing: existing,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this lesson?',
      message:
          'Are you sure you want to delete "${lesson.title}"? '
          'This cannot be undone.',
    );
    if (!ok || !mounted) return;

    try {
      await _service.deleteLesson(lesson.id);
      if (!mounted) return;
      showSnack(context, '"${lesson.title}" deleted');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Delete failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_language.name} Lessons'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Lesson'),
      ),
      body: StreamBuilder<List<Lesson>>(
        stream: _service.getLessonsByLanguage(_language.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(message: '${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          final lessons = snapshot.data ?? const [];
          if (lessons.isEmpty) {
            return EmptyView(
              icon: Icons.menu_book_rounded,
              title: 'No lessons yet',
              message:
                  'Add the first lesson for ${_language.name}. '
                  'For example: Basic Greetings, Common Words, or Numbers.',
              actionLabel: 'Add Lesson',
              onAction: () => _openForm(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 96,
            ),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final lesson = lessons[i];
              return LessonCard(
                lesson: lesson,
                onEdit: () => _openForm(lesson),
                onDelete: () => _confirmDelete(lesson),
              );
            },
          );
        },
      ),
    );
  }
}
