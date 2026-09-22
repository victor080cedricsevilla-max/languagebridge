import 'dart:math';

import 'lesson_model.dart';

class QuizQuestion {
  QuizQuestion({required this.lesson, required List<String> choices})
    : choices = List.unmodifiable(choices);

  final Lesson lesson;
  final List<String> choices;
  String get answer => lesson.translation.trim();
  bool isCorrect(String choice) => choice == answer;
}

/// Builds assessments only from this module's authored dictionary entries.
/// Blank entries and words with conflicting answers cannot become questions.
abstract final class ModuleQuiz {
  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static List<Lesson> eligibleLessons(List<Lesson> lessons) {
    final grouped = <String, List<Lesson>>{};
    for (final lesson in lessons) {
      if (lesson.content.trim().isEmpty || lesson.translation.trim().isEmpty) {
        continue;
      }
      grouped.putIfAbsent(_normalize(lesson.content), () => []).add(lesson);
    }
    return [
      for (final group in grouped.values)
        if (group.map((l) => _normalize(l.translation)).toSet().length == 1)
          group.first,
    ];
  }

  static List<QuizQuestion> generate(
    List<Lesson> lessons, {
    Random? random,
    List<QuizQuestion> previous = const [],
    int limit = 10,
  }) {
    if (limit < 1) return [];
    final rng = random ?? Random();
    final eligible = eligibleLessons(lessons);
    final answers = <String, String>{};
    for (final lesson in eligible) {
      answers.putIfAbsent(
        _normalize(lesson.translation),
        () => lesson.translation.trim(),
      );
    }
    if (eligible.length < 2 || answers.length < 2) return [];
    eligible.shuffle(rng);
    final selected = eligible.take(limit).toList();
    // Avoid exactly the same question order on a consecutive attempt.
    if (selected.length > 1 &&
        selected.length == previous.length &&
        List.generate(
          selected.length,
          (i) => selected[i].id == previous[i].lesson.id,
        ).every((same) => same)) {
      selected.add(selected.removeAt(0));
    }
    return List.unmodifiable(
      selected.map((lesson) {
        final correct = lesson.translation.trim();
        final distractors =
            answers.entries
                .where((e) => e.key != _normalize(correct))
                .map((e) => e.value)
                .toList()
              ..shuffle(rng);
        final choices = [correct, ...distractors.take(3)]..shuffle(rng);
        return QuizQuestion(lesson: lesson, choices: choices);
      }),
    );
  }
}

/// One latest completed assessment per language and user, never a best score.
class AssessmentResult {
  const AssessmentResult({
    required this.score,
    required this.total,
    this.completedAt,
  });

  final int score;
  final int total;
  final DateTime? completedAt;
  int get percentage => total == 0 ? 0 : (100 * score / total).round();
}
