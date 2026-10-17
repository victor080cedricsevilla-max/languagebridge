import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagebridge/data/mock_data.dart';
import 'package:languagebridge/data/starter_modules.dart';
import 'package:languagebridge/models/module_quiz.dart';
import 'package:languagebridge/services/module_repository.dart';

import 'support/test_firestore.dart';

void main() {
  test(
    'all seven Philippine translation languages have complete quiz content',
    () {
      expect(
        StarterModules.all.map((m) => m.code).toSet(),
        kLanguages.where((l) => l.code != 'en').map((l) => l.code).toSet(),
      );
      final ids = <String>{};
      for (final module in StarterModules.all) {
        final lessons = module.lessons();
        expect(lessons, hasLength(60));
        expect(ModuleQuiz.eligibleLessons(lessons), hasLength(60));
        for (final lesson in lessons) {
          expect(ids.add(lesson.id), isTrue);
          expect(lesson.languageId, module.id);
          expect(lesson.meaning, isNotEmpty);
          expect(Uri.parse(lesson.sourceUrl).scheme, 'https');
        }
        final quiz = ModuleQuiz.generate(lessons, random: Random(31));
        expect(quiz, hasLength(10));
        for (final question in quiz) {
          expect(question.choices, hasLength(4));
          expect(question.choices.where(question.isCorrect), hasLength(1));
        }
      }
      expect(ids, hasLength(420));
    },
  );

  test('repository serves every bundled module without the network', () async {
    final repository = BundledModuleRepository(
      userId: 'learner',
      firestore: FakeFirebaseFirestore(),
    );
    final catalog = await repository.watchLanguages().first;
    expect(catalog, hasLength(7));
    expect(
      catalog.map((l) => l.name).toList(),
      [...catalog.map((l) => l.name)]..sort(),
    );
    for (final language in catalog) {
      final lessons = await repository.watchLessons(language.id).first;
      expect(lessons, hasLength(60));
      expect(ModuleQuiz.generate(lessons), hasLength(10));
    }
    expect(await repository.watchLessons('unknown').first, isEmpty);
  });

  test('latest assessment is saved per learner and module', () async {
    final db = FakeFirebaseFirestore();
    final repository = BundledModuleRepository(userId: 'learner', firestore: db);
    expect(await repository.watchLatest('starter-ceb').first, isNull);

    await repository.saveLatest(
      'starter-ceb',
      const AssessmentResult(score: 7, total: 10),
    );
    await repository.saveLatest(
      'starter-ceb',
      const AssessmentResult(score: 4, total: 10),
    );
    final latest = await repository.watchLatest('starter-ceb').first;
    expect(latest?.score, 4);
    expect(latest?.total, 10);
    expect(latest?.completedAt, isNotNull);
    expect(db.records.keys, ['users/learner/assessments/starter-ceb']);

    expect(
      () => repository.saveLatest(
        'starter-ceb',
        const AssessmentResult(score: 11, total: 10),
      ),
      throwsArgumentError,
    );
  });
}
