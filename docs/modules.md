# Language modules and assessments

The floating navigation now has Translate, History, Module, and Profile.
The Module tab combines active records from the `languages` collection with
seven bundled starter modules matching the Philippine translation languages.
Its edit icon opens the existing language and lesson management screens.

## Lesson content

Each language is a module. Its `lessons` records are dictionary entries containing
a word or phrase (`content`), translation, meaning/usage, category, and optional
pronunciation. Learners can search the entries and revisit them at any time.
The new `meaning` field is editable in the lesson form. Older records still load;
their description is displayed when a meaning has not yet been supplied.

The app includes 84 source-referenced entries: 12 each for Filipino / Tagalog,
Kapampangan, Cebuano, Ilocano, Hiligaynon, Central Bikol, and Pangasinan. These
cover everyday words, body and nature, and numbers. Each includes an English
translation, Filipino explanation, and a **Word reference** link. They are
available in the learner view without importing or calling a translation API.
See [the vocabulary and sources](starter-module-sources.md).

To edit or add content:

1. Open **Module → Manage languages & lessons** (the edit icon).
2. Select **Import starter lessons for editing** once to copy the starter
   content into Firestore. This requires connectivity and catalog write access.
3. Open a language, then edit its entries or use **Add Lesson** to add more.
4. Fill in the word, translation, meaning, category, and optional reference URL.

Import reuses matching existing language IDs and preserves existing words,
edits, and inactive flags. Repeating it does not add duplicates. A version
marker means that after import, cloud entries become authoritative, so deleted
lessons stay deleted. Before import, bundled words supplement cloud content;
cloud entries with the same word or stable ID take precedence. Deactivate a
language to hide its module. English remains a translation/gloss language,
not an additional Philippine starter module. Custom empty modules show an
empty state rather than an empty quiz.

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
Publish this additional rule to the connected Firebase project before testing
cloud score saving. Keep any existing deployed catalog/admin restrictions;
the repository's active catalog rules are development rules. This change does
not automatically publish Firestore rules.

## Verification

`flutter test test/module_test.dart` covers shuffling, ambiguous entries,
catalog search, inactive modules, small screens with keyboard insets, scoring,
repeat attempts replacing the score, save retries, abandoning a quiz, and all
four navigation destinations. It uses an in-memory repository; live Firebase
authentication and persistence require a configured project and published rules.

`flutter test test/starter_modules_test.dart` verifies coverage of all seven
languages, quiz-ready vocabulary, compatibility with older documents, optional
import idempotence, existing content preservation, and deletion after import.
Import and repository tests use fake Firestore; they do not write live data.

The older `test/widget_test.dart` still assumes the removed demo-login flow and
does not initialize Firebase, so it fails independently of these module tests.
