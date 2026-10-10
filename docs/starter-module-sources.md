# Starter vocabulary sources

The app bundles 60 beginner words for each of its seven Philippine translation
languages (420 entries). English is the translation/gloss language; Filipino
explains meanings and practice activities. This is a starter vocabulary set,
not a complete dictionary or a fluency course. Bikol entries use Central Bikol.

| Meaning | Filipino / Tagalog | Kapampangan | Cebuano | Ilocano | Hiligaynon | Central Bikol | Pangasinan |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Water | tubig | danum | tubig | danum | tubig | tubig | danum |
| House | bahay | bale | balay | balay | balay | harong | abong |
| Dog | aso | asu | iro | aso | ido | ayam | aso |
| Cat | pusa | pusa | iring | pusa | kuring | ikos | pusa |
| Eye | mata | mata | mata | mata | mata | mata | mata |
| Hand | kamay | gamat | kamot | ima | kamot | kamot | lima |
| Moon | buwan | bulan | bulan | bulan | bulan | bulan | bulan |
| Fire | apoy | api | kalayo | apoy | kalayo | kalayo | apoy |
| One | isa | metung | usa | maysa | isa | saro | sakey |
| Two | dalawa | adwa | duha | dua | duha | duwa | dua |
| Three | tatlo | atlu | tulo | tallo | tatlo | tulo | talo |
| Four | apat | apat | upat | uppat | apat | apat | apat |

## References and attribution

Each entry stores its own `sourceUrl`, visible through **Lesson references** in
the reader's app bar. The original 12 entries above use individual references;
the additional 48 use the comparative vocabulary lists linked below.
Most original links point to the word's language section in English
Wiktionary, for example [danum / Kapampangan](https://en.wiktionary.org/wiki/danum#Kapampangan).
Wiktionary contributors provide the underlying word/gloss references under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
The vocabulary compilation in `lib/data/starter_modules.dart` and
`lib/data/daily_vocabulary.dart` is attributed to
those contributors and shared under the same license; this notice concerns
the vocabulary data, not the application's unrelated code.

Additional entry-specific references:

- Kapampangan **adwa**: [addua, alternative forms](https://en.wiktionary.org/wiki/addua#Kapampangan).
- Hiligaynon **ido**: [Kaufmann dictionary entry, Pinoy Dictionary mirror](https://hiligaynon.pinoydictionary.com/word/ido/).
- Hiligaynon **kamot**: [Kaufmann dictionary entry, Pinoy Dictionary mirror](https://hiligaynon.pinoydictionary.com/word/kamot/).
- Pangasinan **pusa**: [Austronesian Comparative Dictionary, Pangasinan pusá](https://acd.clld.org/valuesets/276-d077f244def8a70e5ea758bd8352fcd8).
- Pangasinan **lima, bulan, apoy, dua, talo, apat**: [Pangasinan language examples, Wikipedia contributors, CC BY-SA 4.0](https://en.wikipedia.org/wiki/Pangasinan_language#Examples).

Version 2 adds 48 everyday concepts for each language. Word/gloss references:

- [Austronesian Swadesh lists, Wikimedia contributors](https://en.wiktionary.org/wiki/Appendix:Austronesian_Swadesh_lists), using the Tagalog, Kapampangan, Cebuano, Ilocano, Central Bikol, and Pangasinan columns.
- [Hiligaynon Swadesh list, Wikimedia contributors](https://en.wiktionary.org/wiki/Appendix:Hiligaynon_Swadesh_list), using listed Hiligaynon forms and variants.

The additions cover family and people, questions, food, body parts, weather,
everyday actions, and descriptions. Question-word entries specify the sense
used (for example, **when** for a future event); the **old** entry describes
objects rather than people. Verb entries teach vocabulary, not a complete
conjugation paradigm. Stable IDs and content version 2 allow the app to add
these words without replacing an editor's changes to the original 12.

Meanings and practice instructions in Filipino were written for this app;
dictionary definitions were not copied verbatim. Common unaccented spellings
are used for display. Phonetic transcriptions are left blank rather than
guessed. A word can have other senses; the quiz tests the sense explicitly
taught in the entry (for example **bulan** = moon, **lima** = hand).

These are source-referenced starter lessons, not material validated by a
native-speaking instructor. Review regional variants and pronunciation with
a qualified speaker before using the modules as a formal language curriculum.
