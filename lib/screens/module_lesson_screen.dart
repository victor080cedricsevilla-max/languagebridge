import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/language_model.dart';
import '../models/lesson_model.dart';
import '../models/module_quiz.dart';
import '../services/module_repository.dart';
import '../utils/date_format.dart';
import '../widgets/state_views.dart';
import 'module_quiz_screen.dart';

/// A continuous, document-style lesson with its assessment at the end.
class ModuleLessonScreen extends StatefulWidget {
  const ModuleLessonScreen({
    super.key,
    required this.language,
    required this.repository,
  });
  final LanguageModel language;
  final ModuleRepository repository;
  @override
  State<ModuleLessonScreen> createState() => _ModuleLessonScreenState();
}

class _ModuleLessonScreenState extends State<ModuleLessonScreen> {
  late final _lessons = widget.repository.watchLessons(widget.language.id);
  late final _latest = widget.repository.watchLatest(widget.language.id);
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    FocusScope.of(context).unfocus();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Lesson>>(
      stream: _lessons,
      builder: (context, snapshot) {
        final lessons = [...?snapshot.data]
          ..sort((a, b) {
            final category = a.category.compareTo(b.category);
            return category == 0 ? a.title.compareTo(b.title) : category;
          });
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.language.name} module'),
            actions: [
              if (lessons.any((l) => l.sourceUrl.isNotEmpty))
                IconButton(
                  tooltip: 'Lesson references',
                  icon: const Icon(Icons.menu_book_outlined),
                  onPressed: () => _showReferences(context, lessons),
                ),
            ],
          ),
          body: snapshot.hasError
              ? const ErrorView(
                  message:
                      'Could not load lessons. Please check your connection.',
                )
              : !snapshot.hasData
              ? const LoadingView()
              : lessons.isEmpty
              ? const MessageView(
                  icon: Icons.auto_stories_outlined,
                  title: 'No lessons published yet',
                  message:
                      'Words and meanings will appear here once lessons are added to this language.',
                )
              : StreamBuilder<AssessmentResult?>(
                  stream: _latest,
                  builder: (context, assessment) {
                    final filtered = lessons
                        .where(
                          (l) =>
                              '${l.content} ${l.translation} ${l.meaning} ${l.title} ${l.description} ${l.category}'
                                  .toLowerCase()
                                  .contains(_query),
                        )
                        .toList();
                    final questionCount = ModuleQuiz.generate(lessons).length;
                    final latest = assessment.data;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: ColoredBox(
                          color: theme.colorScheme.surface,
                          child: ListView(
                            key: const PageStorageKey('lesson-document'),
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                            children: [
                              Text(
                                'LANGUAGE LESSON',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  letterSpacing: 1.6,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.language.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${lessons.length} words and meanings',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Read each section at your own pace. When you reach the end, take the assessment to practice what you learned.',
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _search,
                                onChanged: (value) => setState(
                                  () => _query = value.trim().toLowerCase(),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Find a word or meaning',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: _clearSearch,
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (filtered.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'No matching words. Try another search.',
                                  ),
                                ),
                              for (var i = 0; i < filtered.length; i++) ...[
                                if (i == 0 ||
                                    filtered[i - 1].category !=
                                        filtered[i].category)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 20,
                                      bottom: 8,
                                    ),
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        filtered[i].category.isEmpty
                                            ? 'Vocabulary'
                                            : filtered[i].category,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                _LessonEntry(lesson: filtered[i]),
                              ],
                              if (_query.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                TextButton.icon(
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.menu_book_outlined),
                                  label: const Text('Return to full lesson'),
                                ),
                              ] else ...[
                                const Divider(height: 56),
                                Text(
                                  'End of lesson',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  questionCount == 0
                                      ? 'At least two different words and translations are needed for an assessment.'
                                      : 'Ready to check what you learned? Answer $questionCount questions from this lesson. Questions and choices shuffle each time.',
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Latest assessment',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 6),
                                if (assessment.hasError)
                                  const Text(
                                    'Your latest score could not be loaded. You can still study the lesson.',
                                  )
                                else if (assessment.connectionState ==
                                    ConnectionState.waiting)
                                  const Text('Loading your latest score…')
                                else ...[
                                  Text(
                                    latest == null
                                        ? 'No assessment yet. Learn, then try the quiz.'
                                        : '${latest.score} / ${latest.total} correct · ${latest.percentage}%',
                                  ),
                                  if (latest?.completedAt != null)
                                    Text(
                                      DateFormats.longDate(
                                        latest!.completedAt!,
                                      ),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                                const SizedBox(height: 8),
                                const Text(
                                  'You can repeat the lesson and assessment. Only your latest completed score is shown.',
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  key: const ValueKey('start-module-quiz'),
                                  onPressed: questionCount == 0
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => ModuleQuizScreen(
                                              language: widget.language,
                                              lessons: lessons,
                                              repository: widget.repository,
                                            ),
                                          ),
                                        ),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Take Assessment'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _LessonEntry extends StatelessWidget {
  const _LessonEntry({required this.lesson});
  final Lesson lesson;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final meaning = lesson.meaning.isEmpty
        ? lesson.description
        : lesson.meaning;
    return Padding(
      key: ValueKey('lesson-entry-${lesson.id}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: lesson.content,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' — ${lesson.translation}'),
              ],
            ),
            style: text.bodyLarge?.copyWith(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 4),
          SelectableText(
            meaning.isEmpty
                ? 'A meaning has not been added to this entry yet.'
                : meaning,
            style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}

void _showReferences(BuildContext context, List<Lesson> lessons) {
  final references = <String, List<String>>{};
  for (final lesson in lessons) {
    if (lesson.sourceUrl.isNotEmpty) {
      references.putIfAbsent(lesson.sourceUrl, () => []).add(lesson.content);
    }
  }
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Lesson references'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vocabulary references: Wikimedia contributors, CC BY-SA 4.0, and the dictionaries linked below. Filipino explanations were written for Language Bridge. Spelling and usage can vary by locality.',
              ),
              for (final reference in references.entries) ...[
                const SizedBox(height: 20),
                Text(
                  reference.value.join(', '),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                SelectableText(reference.key),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: reference.key));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reference link copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Copy link'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
