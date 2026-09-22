import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagebridge/data/starter_modules.dart';
import 'package:languagebridge/models/language_model.dart';
import 'package:languagebridge/models/lesson_model.dart';
import 'package:languagebridge/models/module_quiz.dart';
import 'package:languagebridge/screens/module_lesson_screen.dart';
import 'package:languagebridge/screens/module_quiz_screen.dart';
import 'package:languagebridge/screens/module_screen.dart';
import 'package:languagebridge/services/module_repository.dart';
import 'package:languagebridge/theme/app_theme.dart';
import 'package:languagebridge/widgets/glass_navigation_bar.dart';

const language = LanguageModel(
  id: 'test-language',
  name: 'Cebuano',
  description: 'Everyday words and expressions',
  imageUrl: '',
  isActive: true,
);

Lesson entry(int i, {String? word, String? translation}) => Lesson(
  id: 'entry-$i',
  languageId: language.id,
  title: 'Entry $i',
  description: 'Description $i',
  category: 'Everyday words',
  content: word ?? 'Word $i',
  translation: translation ?? 'Translation $i',
  pronunciation: 'Pronunciation $i',
  meaning: 'Meaning and usage for word $i.',
);

class MemoryModules implements ModuleRepository {
  final lessons = List.generate(4, entry);
  final latest = <String, AssessmentResult>{};
  final changes = StreamController<void>.broadcast();
  bool failSave = false;
  int saves = 0;

  @override
  Stream<List<LanguageModel>> watchLanguages() => Stream.value([
    language,
    const LanguageModel(
      id: 'inactive',
      name: 'Hidden module',
      description: '',
      imageUrl: '',
      isActive: false,
    ),
  ]);
  @override
  Stream<List<Lesson>> watchLessons(String id) => Stream.value(lessons);
  @override
  Stream<AssessmentResult?> watchLatest(String id) async* {
    yield latest[id];
    await for (final _ in changes.stream) {
      yield latest[id];
    }
  }

  @override
  Future<void> saveLatest(String id, AssessmentResult result) async {
    if (failSave) throw StateError('Offline');
    saves++;
    latest[id] = result;
    changes.add(null);
  }
}

void phone(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> answerQuiz(
  WidgetTester tester,
  MemoryModules repo, {
  bool correct = true,
}) async {
  for (var i = 0; i < repo.lessons.length; i++) {
    final prompt = tester
        .widget<Text>(find.byKey(const ValueKey('quiz-prompt')))
        .data!;
    final answer = repo.lessons
        .firstWhere((l) => l.content == prompt)
        .translation;
    final options = tester.widgetList<ListTile>(find.byType(ListTile));
    final choice = options.firstWhere(
      (tile) => ((tile.title! as Text).data == answer) == correct,
    );
    await tapVisible(tester, find.byKey(choice.key!));
    await tapVisible(tester, find.byKey(const ValueKey('quiz-next')));
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_MODULE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/module-review').create(recursive: true);
    await File(
      'build/module-review/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_MODULE_UI')) {
      final fontPath = Platform.environment['REVIEW_FONT_PATH'];
      if (fontPath != null) {
        await (FontLoader(
              'Roboto',
            )..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView)))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  test(
    'questions and choices shuffle without losing or misgrading answers',
    () {
      final lessons = List.generate(14, entry);
      final first = ModuleQuiz.generate(lessons, random: Random(5));
      final second = ModuleQuiz.generate(
        lessons,
        random: Random(5),
        previous: first,
      );
      expect(first.length, 10);
      expect(first.map((q) => q.lesson.id).toSet().length, 10);
      expect(
        second.map((q) => q.lesson.id).toList(),
        isNot(first.map((q) => q.lesson.id).toList()),
      );
      for (final question in [...first, ...second]) {
        expect(question.choices.length, 4);
        expect(question.choices.toSet().length, 4);
        expect(question.choices.where(question.isCorrect).length, 1);
      }
      final positions = List.generate(
        12,
        (seed) => ModuleQuiz.generate(lessons, random: Random(seed)).first,
      ).map((q) => q.choices.indexOf(q.answer)).toSet();
      expect(positions.length, greaterThan(1));
    },
  );

  test(
    'ambiguous, blank and duplicate entries cannot create misleading questions',
    () {
      final questions = ModuleQuiz.generate([
        entry(1, word: ' same ', translation: 'One'),
        entry(2, word: 'SAME', translation: 'Two'),
        entry(3, word: ''),
        entry(4, translation: ''),
        entry(5),
        entry(6),
        entry(7, word: 'Word 5', translation: 'Translation 5'),
      ]);
      expect(questions.map((q) => q.lesson.id).toSet(), {'entry-5', 'entry-6'});
      expect(ModuleQuiz.generate([entry(1)]), isEmpty);
      expect(
        ModuleQuiz.generate([
          entry(1, translation: 'Same'),
          entry(2, translation: 'same'),
        ]),
        isEmpty,
      );
    },
  );

  testWidgets(
    'catalog filters inactive modules and fits a small screen with keyboard',
    (tester) async {
      phone(tester, width: 320, height: 640);
      final repo = MemoryModules();
      addTearDown(repo.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ModuleCatalog(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hidden module'), findsNothing);
      await tester.enterText(find.byType(TextField), 'not present');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.text('No matching modules'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'module dictionary, repeat quizzes and latest lower score replace earlier score',
    (tester) async {
      phone(tester);
      final repo = MemoryModules();
      addTearDown(repo.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ModuleLessonScreen(language: language, repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Meaning and usage for word 0.'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('start-module-quiz')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('quiz-next')))
            .onPressed,
        isNull,
      );
      await answerQuiz(tester, repo);
      expect(find.text('4 / 4'), findsOneWidget);
      expect(repo.latest[language.id]!.score, 4);
      await tapVisible(tester, find.text('Retake shuffled quiz'));
      await answerQuiz(tester, repo, correct: false);
      expect(find.text('0 / 4'), findsOneWidget);
      expect(repo.latest.length, 1);
      expect(repo.saves, 2);
      await tapVisible(tester, find.text('Back to lessons'));
      await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text('0 / 4 correct · 0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('save failure retains result and retries without another quiz', (
    tester,
  ) async {
    phone(tester);
    final repo = MemoryModules()..failSave = true;
    addTearDown(repo.changes.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ModuleQuizScreen(
          language: language,
          lessons: repo.lessons,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await answerQuiz(tester, repo);
    expect(find.text('Retry saving'), findsOneWidget);
    expect(repo.latest, isEmpty);
    repo.failSave = false;
    await tapVisible(tester, find.text('Retry saving'));
    expect(repo.latest[language.id]!.score, 4);
    expect(repo.saves, 1);
  });

  testWidgets('leaving unfinished quiz preserves the last assessment', (
    tester,
  ) async {
    phone(tester);
    final repo = MemoryModules();
    repo.latest[language.id] = const AssessmentResult(score: 1, total: 4);
    addTearDown(repo.changes.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ModuleLessonScreen(language: language, repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('start-module-quiz')));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Leave this quiz?'), findsOneWidget);
    await tapVisible(tester, find.text('Leave'));
    expect(repo.latest[language.id]!.score, 1);
    expect(repo.saves, 0);
  });

  testWidgets(
    'starter vocabulary displays meanings and an accessible reference',
    (tester) async {
      phone(tester, width: 360, height: 800);
      final module = StarterModules.all.singleWhere((m) => m.code == 'pam');
      final repo = MemoryModules();
      repo.lessons
        ..clear()
        ..addAll(module.lessons());
      addTearDown(repo.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: RepaintBoundary(
            key: const ValueKey('capture'),
            child: ModuleLessonScreen(
              language: module.language,
              repository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'danum');
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == 'danum',
        ),
        findsOneWidget,
      );
      expect(find.text('Water'), findsOneWidget);
      await capture(tester, 'kapampangan-starter-lesson');
      await tapVisible(tester, find.text('Word reference'));
      expect(
        find.text('https://en.wiktionary.org/wiki/danum#Kapampangan'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Close'));
      await tapVisible(tester, find.byKey(const ValueKey('start-module-quiz')));
      expect(find.byKey(const ValueKey('quiz-prompt')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('glass navbar selects all four tabs and module layout renders', (
    tester,
  ) async {
    phone(tester);
    final repo = MemoryModules();
    addTearDown(repo.changes.close);
    var selected = 2;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: const ValueKey('capture'),
          child: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              extendBody: true,
              body: SafeArea(
                top: false,
                child: ModuleCatalog(repository: repo),
              ),
              bottomNavigationBar: GlassNavigationBar(
                selectedIndex: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < GlassNavigationBar.items.length; i++) {
      await tester.tap(
        find.byKey(
          ValueKey('nav-${GlassNavigationBar.items[i].label.toLowerCase()}'),
        ),
      );
      await tester.pumpAndSettle();
      expect(selected, i);
    }
    await tester.tap(find.byKey(const ValueKey('nav-module')));
    await tester.pumpAndSettle();
    await capture(tester, 'module-and-navigation');
    expect(tester.takeException(), isNull);
  });
}
