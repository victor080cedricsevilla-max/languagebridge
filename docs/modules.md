# Language modules and assessments

The floating navigation has Translate, History, Module, and Profile.
The Module tab lists the seven language modules bundled with the app, one for
each Philippine translation language. Learners cannot add or edit languages or
lessons; the content is read-only in the app.

## Lesson content

Each language is a module. Its lessons are dictionary entries containing
a word or phrase (`content`), translation, meaning/usage, category, and optional
pronunciation. The reader displays a continuous document with topic headings,
words, translations, and Filipino meanings, rather than a card for every word.
Learners can search the entries and revisit them at any time. Search results
offer **Return to full lesson**; **Take Assessment** appears after the complete
lesson, alongside the latest assessment score.

The app includes 420 source-referenced entries: 60 each for Filipino / Tagalog,
Kapampangan, Cebuano, Ilocano, Hiligaynon, Central Bikol, and Pangasinan. These
cover people and family, questions, food, body parts, nature and weather,
everyday actions, descriptions, and numbers. Each includes an English
translation, Filipino explanation, and source URL. The app bar's **Lesson
references** button groups the reference links and their associated words. They are
available offline and without calling a translation API.
See [the vocabulary and sources](starter-module-sources.md).

## Publishing new content

Lessons and languages change only through an app update:

1. Add or edit words in `lib/data/starter_modules.dart` (the original 12
   concepts) or `lib/data/daily_vocabulary.dart` (the everyday vocabulary). To
   add a dialect, add a `StarterModule` entry and its word in every
   `dailyVocabulary` item, and add the language to `kLanguages` in
   `lib/data/mock_data.dart`; the tests require every module to match a
   translation language.
2. Keep existing lesson IDs (`starter-{code}-{concept}`) and module IDs
   (`starter-{code}`) unchanged, so learners' saved assessments stay linked.
3. Run `flutter test`, bump `version:` in `pubspec.yaml`, and publish the build.
   Learners receive the new content when they update the app.

English remains a translation/gloss language, not an additional Philippine
module. A module whose `isActive` is false is hidden.

## Assessment behavior

- The end-of-module quiz draws up to ten questions from that language's entries.
- Each attempt randomizes question order and up to four answer choices.
- Retaking from the result page also prevents an identical consecutive question
  order. A limited lesson bank necessarily reuses words across attempts.
- Blank entries and words with conflicting translations are excluded.
- At least two distinct words and two distinct translations are needed.
- Questions are graded against the authored translation, independent of the
  position of the shuffled correct choice. Answers are reviewed after completion.
- An abandoned attempt does not save a result. Completed attempts overwrite the
  prior score even when the newer score is lower.
- Learners can retry saving on an error without answering the quiz again.

## Latest-score persistence

One document is stored at
`users/{userId}/assessments/{languageId}` with `score`, `total`, and a server
`completedAt` timestamp. This is a practice assessment graded in the client, not
a proctored or tamper-proof exam. The UI displays the latest assessment for the
current user and language, not a history or personal-best score.

The assessment rules in `firestore.rules` allow only the matching signed-in
user to access these documents and validate the score range and timestamp.
Firestore stores no catalog: every path other than a user's own history and
assessments is denied. Changes to `firestore.rules` take effect only after they
are published to the Firebase project.

## Verification

`flutter test test/module_test.dart` covers shuffling, ambiguous entries,
catalog search, inactive modules, small screens with keyboard insets, scoring,
repeat attempts replacing the score, save retries, abandoning a quiz, and all
four navigation destinations. It also checks the continuous 60-word reader,
search, references, and assessment placement at the end. It uses an in-memory
repository; live Firebase
authentication and persistence require a configured project and published rules.

`flutter test test/starter_modules_test.dart` verifies coverage of all seven
languages with unique IDs, meanings and references; that the repository serves
every module offline with quiz-ready lessons; and that the latest assessment is
saved per learner and module. Assessment tests use an in-memory fake Firestore
and do not write live data.

The older `test/widget_test.dart` still assumes the removed demo-login flow and
does not initialize Firebase, so it fails independently of these module tests.
