import 'package:flutter/material.dart';

import '../models/language_model.dart';
import '../models/lesson_model.dart';
import '../models/module_quiz.dart';
import '../services/module_repository.dart';
import '../widgets/state_views.dart';

class ModuleQuizScreen extends StatefulWidget {
  const ModuleQuizScreen({
    super.key,
    required this.language,
    required this.lessons,
    required this.repository,
  });
  final LanguageModel language;
  final List<Lesson> lessons;
  final ModuleRepository repository;

  @override
  State<ModuleQuizScreen> createState() => _ModuleQuizScreenState();
}

class _ModuleQuizScreenState extends State<ModuleQuizScreen> {
  late List<QuizQuestion> _questions = ModuleQuiz.generate(widget.lessons);
  final _answers = <int, String>{};
  int _index = 0;
  AssessmentResult? _result;
  bool _saving = false;
  bool _saved = false;
  String? _saveError;

  Future<void> _save() async {
    if (_saving || _saved || _result == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.repository
          .saveLatest(widget.language.id, _result!)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _saved = true;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'We could not confirm that your score was saved. Check your connection and retry saving before starting another quiz.';
      });
    }
  }

  void _next() {
    if (!_answers.containsKey(_index)) return;
    if (_index < _questions.length - 1) {
      setState(() => _index++);
    } else {
      final score = _answers.entries
          .where((e) => _questions[e.key].isCorrect(e.value))
          .length;
      setState(
        () =>
            _result = AssessmentResult(score: score, total: _questions.length),
      );
      _save();
    }
  }

  void _retake() {
    setState(() {
      _questions = ModuleQuiz.generate(widget.lessons, previous: _questions);
      _answers.clear();
      _index = 0;
      _result = null;
      _saved = false;
      _saveError = null;
    });
  }

  Future<bool> _confirmLeave() async {
    if (_saving) return false;
    if (_saved || _questions.isEmpty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              _result == null ? 'Leave this quiz?' : 'Leave before saving?',
            ),
            content: Text(
              _result == null
                  ? 'This unfinished attempt will not replace your latest assessment.'
                  : 'Your latest score has not been confirmed as saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || _saved || _questions.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) {
          setState(() => _allowPop = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('${widget.language.name} quiz')),
        body: _questions.isEmpty
            ? const MessageView(
                icon: Icons.quiz_outlined,
                title: 'More lessons needed',
                message:
                    'Add at least two different words and translations to create a quiz.',
              )
            : _result == null
            ? _questionView(context)
            : _resultView(context),
      ),
    );
  }

  Widget _questionView(BuildContext context) {
    final theme = Theme.of(context);
    final question = _questions[_index];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Question ${_index + 1} of ${_questions.length}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_index + 1) / _questions.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 32),
        Text('Choose the translation', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              question.lesson.content,
              key: const ValueKey('quiz-prompt'),
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < question.choices.length; i++) ...[
          Semantics(
            selected: _answers[_index] == question.choices[i],
            button: true,
            child: Card(
              color: _answers[_index] == question.choices[i]
                  ? theme.colorScheme.primaryContainer
                  : null,
              child: ListTile(
                key: ValueKey('quiz-choice-$i'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: CircleAvatar(
                  radius: 17,
                  child: Text(String.fromCharCode(65 + i)),
                ),
                title: Text(question.choices[i]),
                trailing: _answers[_index] == question.choices[i]
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                onTap: () =>
                    setState(() => _answers[_index] = question.choices[i]),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('quiz-next'),
          onPressed: _answers.containsKey(_index) ? _next : null,
          child: Text(
            _index == _questions.length - 1 ? 'Finish quiz' : 'Next question',
          ),
        ),
      ],
    );
  }

  Widget _resultView(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.task_alt_rounded,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Assessment complete',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          '${result.score} / ${result.total}',
          key: const ValueKey('quiz-score'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text('${result.percentage}% correct', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          result.score == result.total
              ? 'Well done! Revisit the lessons to keep practicing.'
              : 'Review the answers below, then revisit the words you want to practice.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (_saving) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text(
            'Saving your latest assessment…',
            textAlign: TextAlign.center,
          ),
        ],
        if (_saved)
          const Text(
            'Latest assessment saved. Your previous score has been replaced.',
            textAlign: TextAlign.center,
          ),
        if (_saveError != null) ...[
          Text(_saveError!, style: TextStyle(color: theme.colorScheme.error)),
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Retry saving'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saved ? _retake : null,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Retake shuffled quiz'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
          child: const Text('Back to lessons'),
        ),
        const SizedBox(height: 28),
        Text('Answer review', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        for (var i = 0; i < _questions.length; i++) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _questions[i].isCorrect(_answers[i]!)
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: _questions[i].isCorrect(_answers[i]!)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _questions[i].lesson.content,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Your answer: ${_answers[i]}'),
                  if (!_questions[i].isCorrect(_answers[i]!))
                    Text('Correct translation: ${_questions[i].answer}'),
                  if (_questions[i].lesson.meaning.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_questions[i].lesson.meaning),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
