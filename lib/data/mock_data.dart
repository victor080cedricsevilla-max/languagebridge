import '../models/language.dart';

/// Languages offered in the translator.
///
/// Focused on Philippine languages — the audience for Language Bridge — plus
/// English as the common source. Codes are Google Cloud Translation API codes,
/// so they pass straight through to [TranslationApi].
const kLanguages = <Language>[
  Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
  Language(code: 'tl', name: 'Filipino', nativeName: 'Tagalog', flag: '🇵🇭'),
  Language(code: 'ceb', name: 'Cebuano', nativeName: 'Bisaya', flag: '🇵🇭'),
  Language(code: 'ilo', name: 'Ilocano', nativeName: 'Ilokano', flag: '🇵🇭'),
  Language(code: 'hil', name: 'Hiligaynon', nativeName: 'Ilonggo', flag: '🇵🇭'),
  Language(code: 'war', name: 'Waray', nativeName: 'Waray-Waray', flag: '🇵🇭'),
];

Language languageByCode(String code) =>
    kLanguages.firstWhere((l) => l.code == code, orElse: () => kLanguages.first);
