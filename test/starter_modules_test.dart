import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagebridge/data/mock_data.dart';
import 'package:languagebridge/data/starter_modules.dart';
import 'package:languagebridge/models/language_model.dart';
import 'package:languagebridge/models/lesson_model.dart';
import 'package:languagebridge/models/module_quiz.dart';
import 'package:languagebridge/services/module_repository.dart';
import 'package:languagebridge/services/starter_content_service.dart';

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

  test('existing aliases, inactive flags and edited words take precedence', () {
    final module = StarterModules.all.first;
    final existing = module.language.copyWith(name: 'Tagalog', isActive: false);
    final catalog = StarterModules.mergeLanguages([existing]);
    expect(catalog, hasLength(7));
    expect(catalog.singleWhere((l) => l.id == existing.id).isActive, isFalse);
    final edited = module.lessons().first.copyWith(
      content: ' TUBIG ',
      meaning: 'Reviewed by the teacher',
    );
    final merged = StarterModules.mergeLessons(module, module.id, [edited]);
    expect(merged, hasLength(60));
    expect(merged.first.meaning, 'Reviewed by the teacher');
  });

  test(
    'import is repeatable and does not restore removed imported lessons',
    () async {
      final db = FakeFirebaseFirestore();
      final service = StarterContentService(firestore: db);
      expect(await service.importAll(), 420);
      expect((await db.collection('languages').get()).docs, hasLength(7));
      expect((await db.collection('lessons').get()).docs, hasLength(420));
      await db.collection('lessons').doc('starter-pam-water').update({
        'meaning': 'Teacher correction',
      });
      await db.collection('lessons').doc('starter-pam-house').delete();
      expect(await service.importAll(), 0);
      expect((await db.collection('lessons').get()).docs, hasLength(419));
      expect(
        (await db.collection('lessons').doc('starter-pam-water').get())
            .data()?['meaning'],
        'Teacher correction',
      );

      final repository = FirestoreModuleRepository(
        userId: 'learner',
        firestore: db,
      );
      await repository.watchLanguages().first;
      final lessons = await repository.watchLessons('starter-pam').first;
      expect(lessons, hasLength(59));
      expect(lessons.any((l) => l.id == 'starter-pam-house'), isFalse);
    },
  );

  test(
    'import reuses existing language and keeps existing vocabulary',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('languages').doc('teacher-language').set({
        'name': 'Ilokano',
        'description': 'Teacher description',
        'imageUrl': '',
        'isActive': false,
      });
      final lesson = StarterModules.all
          .singleWhere((m) => m.code == 'ilo')
          .lessons(languageId: 'teacher-language')
          .first
          .copyWith(meaning: 'Teacher meaning');
      await db.collection('lessons').doc('teacher-lesson').set(lesson.toMap());
      expect(await StarterContentService(firestore: db).importAll(), 419);
      final languages = (await db.collection('languages').get()).docs
          .map(LanguageModel.fromDoc)
          .toList();
      expect(languages, hasLength(7));
      final ilocano = languages.singleWhere((l) => l.id == 'teacher-language');
      expect(ilocano.description, 'Teacher description');
      expect(ilocano.isActive, isFalse);
      final lessons = await db
          .collection('lessons')
          .where('languageId', isEqualTo: 'teacher-language')
          .get();
      expect(lessons.docs, hasLength(60));
      expect(
        lessons.docs
            .singleWhere((l) => l.id == 'teacher-lesson')
            .data()['meaning'],
        'Teacher meaning',
      );
      final repository = FirestoreModuleRepository(
        userId: 'learner',
        firestore: db,
      );
      final visible = await repository.watchLanguages().first;
      expect(visible, hasLength(6));
      expect(visible.any((l) => l.id == 'teacher-language'), isFalse);
    },
  );

  test(
    'empty cloud catalog provides all modules and quiz-ready lessons',
    () async {
      final repository = FirestoreModuleRepository(
        userId: 'learner',
        firestore: FakeFirebaseFirestore(),
      );
      final catalog = await repository.watchLanguages().first;
      expect(catalog, hasLength(7));
      for (final language in catalog) {
        final lessons = await repository
            .watchLessons(language.id)
            .skip(1)
            .first;
        expect(ModuleQuiz.generate(lessons), hasLength(10));
      }
    },
  );

  test(
    'version 1 gets new words without restoring deleted old words or edits',
    () async {
      final db = FakeFirebaseFirestore();
      final module = StarterModules.all.singleWhere((m) => m.code == 'pam');
      await db.collection('languages').doc(module.id).set({
        ...module.language.toMap(),
        'starterContentVersion': 1,
      });
      // The original twelve records, with one intentionally deleted.
      for (final lesson in module.lessons().take(12)) {
        if (lesson.id.endsWith('-house')) continue;
        await db.collection('lessons').doc(lesson.id).set(lesson.toMap());
      }
      await db.collection('lessons').doc('starter-pam-water').update({
        'meaning': 'Teacher edit',
      });
      final repo = FirestoreModuleRepository(userId: 'learner', firestore: db);
      await repo.watchLanguages().first;
      final visible = await repo.watchLessons(module.id).first;
      expect(visible, hasLength(59));
      expect(visible.any((l) => l.id == 'starter-pam-house'), isFalse);
      expect(
        visible.singleWhere((l) => l.id == 'starter-pam-water').meaning,
        'Teacher edit',
      );
      expect(visible.any((l) => l.id == 'starter-pam-mother'), isTrue);

      final importer = StarterContentService(firestore: db);
      expect(
        await importer.importAll(),
        408,
      ); // 48 new + 6 untouched modules x 60.
      expect(await importer.importAll(), 0);
      final saved = await db
          .collection('lessons')
          .where('languageId', isEqualTo: module.id)
          .get();
      expect(saved.docs, hasLength(59));
      expect(saved.docs.any((d) => d.id == 'starter-pam-house'), isFalse);
      expect(
        (await db.collection('languages').doc(module.id).get())
            .data()?['starterContentVersion'],
        2,
      );
    },
  );

  test(
    'lesson references round-trip and older documents remain readable',
    () async {
      final db = FakeFirebaseFirestore();
      final ref = db.collection('lessons').doc('word');
      await ref.set({'content': 'danum', 'translation': 'Water'});
      final old = Lesson.fromDoc(await ref.get());
      expect(old.meaning, isEmpty);
      expect(old.sourceUrl, isEmpty);
      final lesson = StarterModules.all[1].lessons().first;
      await ref.set(lesson.toMap());
      final saved = Lesson.fromDoc(await ref.get());
      expect(saved.sourceUrl, lesson.sourceUrl);
      expect(saved.meaning, lesson.meaning);
    },
  );
}
