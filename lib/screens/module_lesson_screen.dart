import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/language_model.dart';
import '../models/lesson_model.dart';
import '../models/module_quiz.dart';
import '../services/module_repository.dart';
import '../widgets/latest_assessment_card.dart';
import '../widgets/state_views.dart';
import 'module_quiz_screen.dart';

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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.language.name} module')),
      body: StreamBuilder<AssessmentResult?>(
        stream: _latest,
        builder: (context, assessment) => StreamBuilder<List<Lesson>>(
          stream: _lessons,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const ErrorView(
                message:
                    'Could not load lessons. Please check your connection.',
              );
            }
            if (!snapshot.hasData) return const LoadingView();
            final lessons = [...snapshot.data!]
              ..sort((a, b) {
                final category = a.category.compareTo(b.category);
                return category == 0 ? a.title.compareTo(b.title) : category;
              });
            if (lessons.isEmpty) {
              return const MessageView(
                icon: Icons.auto_stories_outlined,
                title: 'No lessons published yet',
                message:
                    'Words, translations, and meanings will appear here once lessons are added to this language.',
              );
            }
            final filtered = lessons
                .where(
                  (l) =>
                      '${l.content} ${l.translation} ${l.meaning} ${l.title} ${l.description} ${l.category}'
                          .toLowerCase()
                          .contains(_query),
                )
                .toList();
            final questionCount = ModuleQuiz.generate(lessons).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Your pocket dictionary',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${lessons.length} lessons · Learn at your own pace. You can revisit every lesson and repeat the quiz anytime.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (assessment.hasError)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Your latest score could not be loaded. You can still study the lessons.',
                      ),
                    ),
                  )
                else if (assessment.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else
                  LatestAssessmentCard(result: assessment.data),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search words, meanings or categories',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No matching words. Try another search.'),
                  ),
                for (final lesson in filtered) ...[
                  _DictionaryEntry(lesson: lesson),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          color: theme.colorScheme.primary,
                          size: 30,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Put your learning to the test',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          questionCount == 0
                              ? 'The quiz needs at least two different words with different translations. More lesson content is needed before you can start.'
                              : '$questionCount questions from the whole module. Questions and answer choices shuffle on each attempt. Only your latest completed score is kept.',
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
                          label: const Text('Start quiz'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DictionaryEntry extends StatelessWidget {
  const _DictionaryEntry({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meaning = lesson.meaning.isNotEmpty
        ? lesson.meaning
        : lesson.description;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson.category.isNotEmpty) ...[
              Text(
                lesson.category.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SelectableText(lesson.content, style: theme.textTheme.titleLarge),
            if (lesson.pronunciation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '/ ${lesson.pronunciation} /',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 28),
            Text('TRANSLATION', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            SelectableText(
              lesson.translation,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Text('MEANING & USAGE', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            SelectableText(
              meaning.isEmpty
                  ? 'A meaning has not been added to this entry yet.'
                  : meaning,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (lesson.sourceUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Word reference'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${lesson.content} — ${lesson.translation}'),
                          const SizedBox(height: 12),
                          const Text(
                            'Reference for this word and translation. Spelling and usage can vary by locality.',
                          ),
                          const SizedBox(height: 12),
                          SelectableText(lesson.sourceUrl),
                          if (lesson.sourceUrl.contains('wiktionary.org') ||
                              lesson.sourceUrl.contains('wikipedia.org')) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Vocabulary reference: Wikimedia contributors · CC BY-SA 4.0. Starter explanations were written for Language Bridge.',
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: lesson.sourceUrl),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reference link copied'),
                              ),
                            );
                          }
                        },
                        child: const Text('Copy link'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.info_outline_rounded, size: 17),
                label: const Text('Word reference'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
