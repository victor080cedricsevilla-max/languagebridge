import '../models/language_model.dart';
import '../models/lesson_model.dart';

/// Bundled vocabulary, available without calling a translation API.
/// Sources and editorial notes: docs/starter-module-sources.md.
class StarterModule {
  const StarterModule(
    this.code,
    this.name,
    this.aliases,
    this.words, {
    this.note = '',
  });
  final String code;
  final String name;
  final List<String> aliases;
  final List<String> words;
  final String note;

  String get id => 'starter-$code';
  LanguageModel get language => LanguageModel(
    id: id,
    name: name,
    imageUrl: '',
    isActive: true,
    description:
        '12 beginner words: everyday objects, body, nature, and numbers.${note.isEmpty ? '' : ' $note'}',
  );

  bool matches(LanguageModel language) =>
      language.id == id ||
      [name, ...aliases].any(
        (alias) =>
            StarterModules.normalize(alias) ==
            StarterModules.normalize(language.name),
      );

  List<Lesson> lessons({String? languageId}) =>
      List.generate(words.length, (index) {
        final concept = StarterModules.concepts[index];
        return Lesson(
          id: '$id-${concept.id}',
          languageId: languageId ?? id,
          title: concept.english,
          description: 'Beginner vocabulary: ${concept.english.toLowerCase()}.',
          category: concept.category,
          content: words[index],
          translation: concept.english,
          meaning: concept.meaning,
          pronunciation: '',
          sourceUrl: _source(index),
        );
      });

  String _source(int index) {
    if (code == 'hil' && index == 2) {
      return 'https://hiligaynon.pinoydictionary.com/word/ido/';
    }
    if (code == 'hil' && index == 5) {
      return 'https://hiligaynon.pinoydictionary.com/word/kamot/';
    }
    if (code == 'pam' && index == 9) {
      return 'https://en.wiktionary.org/wiki/addua#Kapampangan';
    }
    if (code == 'pag' && index == 3) {
      return 'https://acd.clld.org/valuesets/276-d077f244def8a70e5ea758bd8352fcd8';
    }
    if (code == 'pag' && [5, 6, 7, 9, 10, 11].contains(index)) {
      return 'https://en.wikipedia.org/wiki/Pangasinan_language#Examples';
    }
    final section = switch (code) {
      'tl' => 'Tagalog',
      'pam' => 'Kapampangan',
      'ceb' => 'Cebuano',
      'ilo' => 'Ilocano',
      'hil' => 'Hiligaynon',
      'bik' => 'Central_Bikol',
      _ => 'Pangasinan',
    };
    return 'https://en.wiktionary.org/wiki/${Uri.encodeComponent(words[index].toLowerCase())}#$section';
  }
}

abstract final class StarterModules {
  static String normalize(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  // Words align with the concepts below. No guessed phonetic transcriptions.
  static const all = <StarterModule>[
    StarterModule(
      'tl',
      'Filipino / Tagalog',
      ['Filipino', 'Tagalog'],
      [
        'tubig',
        'bahay',
        'aso',
        'pusa',
        'mata',
        'kamay',
        'buwan',
        'apoy',
        'isa',
        'dalawa',
        'tatlo',
        'apat',
      ],
    ),
    StarterModule(
      'pam',
      'Kapampangan',
      ['Pampango'],
      [
        'danum',
        'bale',
        'asu',
        'pusa',
        'mata',
        'gamat',
        'bulan',
        'api',
        'metung',
        'adwa',
        'atlu',
        'apat',
      ],
    ),
    StarterModule(
      'ceb',
      'Cebuano',
      ['Sebwano', 'Bisaya', 'Cebuano / Sebwano'],
      [
        'tubig',
        'balay',
        'iro',
        'iring',
        'mata',
        'kamot',
        'bulan',
        'kalayo',
        'usa',
        'duha',
        'tulo',
        'upat',
      ],
    ),
    StarterModule(
      'ilo',
      'Ilocano',
      ['Ilokano', 'Iloko', 'Ilocano / Ilokano'],
      [
        'danum',
        'balay',
        'aso',
        'pusa',
        'mata',
        'ima',
        'bulan',
        'apoy',
        'maysa',
        'dua',
        'tallo',
        'uppat',
      ],
    ),
    StarterModule(
      'hil',
      'Hiligaynon',
      ['Ilonggo'],
      [
        'tubig',
        'balay',
        'ido',
        'kuring',
        'mata',
        'kamot',
        'bulan',
        'kalayo',
        'isa',
        'duha',
        'tatlo',
        'apat',
      ],
    ),
    StarterModule(
      'bik',
      'Bikol',
      ['Central Bikol', 'Bicol', 'Bicolano', 'Bikolano'],
      [
        'tubig',
        'harong',
        'ayam',
        'ikos',
        'mata',
        'kamot',
        'bulan',
        'kalayo',
        'saro',
        'duwa',
        'tulo',
        'apat',
      ],
      note: 'Central Bikol vocabulary.',
    ),
    StarterModule(
      'pag',
      'Pangasinan',
      ['Pangasinense'],
      [
        'danum',
        'abong',
        'aso',
        'pusa',
        'mata',
        'lima',
        'bulan',
        'apoy',
        'sakey',
        'dua',
        'talo',
        'apat',
      ],
    ),
  ];

  static const concepts = <({String id, String english, String category, String meaning})>[
    (
      id: 'water',
      english: 'Water',
      category: '01 · Everyday words',
      meaning:
          'Tubig. Likidong ginagamit sa pag-inom, pagluluto, at paghuhugas. Tandaan ang salitang ito kapag humihingi ng maiinom.',
    ),
    (
      id: 'house',
      english: 'House',
      category: '01 · Everyday words',
      meaning:
          'Bahay. Gusaling tinitirhan ng isang tao o pamilya. Dito, ang tinutukoy ay ang tirahan.',
    ),
    (
      id: 'dog',
      english: 'Dog',
      category: '01 · Everyday words',
      meaning:
          'Aso. Hayop na madalas alagaan sa bahay. Ang lesson na ito ay tumutukoy sa hayop, hindi sa ibang posibleng kahulugan ng salita.',
    ),
    (
      id: 'cat',
      english: 'Cat',
      category: '01 · Everyday words',
      meaning:
          'Pusa. Maliit na hayop na may bigote at madalas alagaan sa bahay. Ihambing ang salita nito sa salita para sa aso.',
    ),
    (
      id: 'eye',
      english: 'Eye',
      category: '02 · Body and nature',
      meaning:
          'Mata. Bahagi ng katawan na ginagamit sa pagtingin. Sa lesson na ito, bahagi ng katawan ang kahulugan ng salita.',
    ),
    (
      id: 'hand',
      english: 'Hand',
      category: '02 · Body and nature',
      meaning:
          'Kamay. Bahagi ng katawan na ginagamit sa paghawak at pagsusulat. Pangalan ng bahagi ng katawan ang tinutukoy dito.',
    ),
    (
      id: 'moon',
      english: 'Moon',
      category: '02 · Body and nature',
      meaning:
          'Buwan sa langit. Ang tinutukoy dito ay ang likas na satelayt ng daigdig, hindi ang buwan sa kalendaryo.',
    ),
    (
      id: 'fire',
      english: 'Fire',
      category: '02 · Body and nature',
      meaning:
          'Apoy. Init at liwanag na nalilikha kapag may nasusunog. Pangngalan ang gamit ng salita sa lesson na ito.',
    ),
    (
      id: 'one',
      english: 'One',
      category: '03 · Numbers',
      meaning:
          'Isa (1). Bilang para sa isang bagay. Pagsasanay: tumuro ng isang lapis habang binibigkas ang salita.',
    ),
    (
      id: 'two',
      english: 'Two',
      category: '03 · Numbers',
      meaning:
          'Dalawa (2). Bilang na kasunod ng isa. Pagsasanay: magtabi ng dalawang bagay at bilangin ang mga ito.',
    ),
    (
      id: 'three',
      english: 'Three',
      category: '03 · Numbers',
      meaning:
          'Tatlo (3). Bilang na kasunod ng dalawa. Pagsasanay: magbilang mula isa hanggang tatlo sa wikang pinag-aaralan.',
    ),
    (
      id: 'four',
      english: 'Four',
      category: '03 · Numbers',
      meaning:
          'Apat (4). Bilang na kasunod ng tatlo. Pagsasanay: bilangin ang apat na sulok ng isang parisukat.',
    ),
  ];

  static StarterModule? forLanguage(LanguageModel language) {
    for (final module in all) {
      if (module.matches(language)) return module;
    }
    return null;
  }

  static StarterModule? forId(String id) {
    for (final module in all) {
      if (module.id == id) return module;
    }
    return null;
  }

  /// Existing IDs, edits, and inactive flags take precedence over bundled data.
  static List<LanguageModel> mergeLanguages(List<LanguageModel> remote) {
    return [
      ...remote,
      for (final module in all)
        if (!remote.any(module.matches)) module.language,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Lesson> mergeLessons(
    StarterModule module,
    String languageId,
    List<Lesson> remote,
  ) {
    final words = remote.map((l) => normalize(l.content)).toSet();
    final ids = remote.map((l) => l.id).toSet();
    return [
      ...remote,
      ...module
          .lessons(languageId: languageId)
          .where(
            (l) => !words.contains(normalize(l.content)) && !ids.contains(l.id),
          ),
    ];
  }
}
