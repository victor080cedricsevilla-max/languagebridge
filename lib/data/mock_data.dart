import '../models/language.dart';
import '../models/translation_record.dart';
import '../models/user_profile.dart';

/// Languages offered in the picker. Trimmed to a demo-friendly set; the real
/// build would pull this from the Translation API's supported-languages call.
const kLanguages = <Language>[
  Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
  Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino', flag: '🇵🇭'),
  Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
  Language(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
  Language(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
  Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
  Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
  Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
  Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
];

Language languageByCode(String code) =>
    kLanguages.firstWhere((l) => l.code == code, orElse: () => kLanguages.first);

/// The signed-in user for the prototype.
final kDemoUser = UserProfile(
  name: 'Cedric Santos',
  email: 'codebp2025@gmail.com',
  memberSince: DateTime(2026, 3, 14),
);

/// Seed history so the History screen has something to show on first run.
/// Times are relative to launch so the date grouping always demos correctly.
List<TranslationRecord> seedHistory() {
  final now = DateTime.now();
  return [
    TranslationRecord(
      id: 'h1',
      sourceText: 'Good morning, how are you?',
      translatedText: 'Magandang umaga, kumusta ka?',
      sourceLangCode: 'en',
      targetLangCode: 'fil',
      createdAt: now.subtract(const Duration(minutes: 12)),
      isFavorite: true,
    ),
    TranslationRecord(
      id: 'h2',
      sourceText: 'Where is the nearest hospital?',
      translatedText: '¿Dónde está el hospital más cercano?',
      sourceLangCode: 'en',
      targetLangCode: 'es',
      createdAt: now.subtract(const Duration(hours: 2)),
      source: TranslationSource.voice,
    ),
    TranslationRecord(
      id: 'h3',
      sourceText: 'No Parking — Tow Away Zone',
      translatedText: 'Bawal Pumarada — Hihilahin ang Sasakyan',
      sourceLangCode: 'en',
      targetLangCode: 'fil',
      createdAt: now.subtract(const Duration(hours: 5)),
      source: TranslationSource.camera,
    ),
    TranslationRecord(
      id: 'h4',
      sourceText: 'Thank you very much for your help',
      translatedText: 'ご協力ありがとうございます',
      sourceLangCode: 'en',
      targetLangCode: 'ja',
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      isFavorite: true,
    ),
    TranslationRecord(
      id: 'h5',
      sourceText: 'Magkano po ito?',
      translatedText: 'How much is this?',
      sourceLangCode: 'fil',
      targetLangCode: 'en',
      createdAt: now.subtract(const Duration(days: 1, hours: 7)),
      source: TranslationSource.voice,
    ),
    TranslationRecord(
      id: 'h6',
      sourceText: 'I would like to schedule an appointment',
      translatedText: 'Je voudrais prendre un rendez-vous',
      sourceLangCode: 'en',
      targetLangCode: 'fr',
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    TranslationRecord(
      id: 'h7',
      sourceText: 'Please speak more slowly',
      translatedText: '천천히 말씀해 주세요',
      sourceLangCode: 'en',
      targetLangCode: 'ko',
      createdAt: now.subtract(const Duration(days: 6, hours: 2)),
      isFavorite: true,
    ),
  ];
}

/// Phrases the fake translator knows, keyed by `sourceLang>targetLang`.
/// Everything else falls back to a clearly-labelled demo response.
const kPhrasebook = <String, Map<String, String>>{
  'en>fil': {
    'hello': 'Kumusta',
    'hi': 'Kumusta',
    'thank you': 'Salamat',
    'thank you very much': 'Maraming salamat',
    'good morning': 'Magandang umaga',
    'good evening': 'Magandang gabi',
    'how are you?': 'Kumusta ka?',
    'how are you': 'Kumusta ka',
    'what is your name?': 'Ano ang pangalan mo?',
    'i am hungry': 'Gutom na ako',
    'where is the bathroom?': 'Nasaan ang banyo?',
    'how much is this?': 'Magkano ito?',
    'i need help': 'Kailangan ko ng tulong',
    'please speak slowly': 'Pakidahan-dahan po ang pagsasalita',
    'excuse me': 'Paumanhin',
    'good night': 'Magandang gabi',
    'see you tomorrow': 'Kita tayo bukas',
    'i love you': 'Mahal kita',
    'no parking': 'Bawal pumarada',
  },
  'fil>en': {
    'kumusta': 'Hello',
    'kumusta ka?': 'How are you?',
    'kumusta ka': 'How are you',
    'salamat': 'Thank you',
    'maraming salamat': 'Thank you very much',
    'magandang umaga': 'Good morning',
    'magandang gabi': 'Good evening',
    'magkano ito?': 'How much is this?',
    'magkano po ito?': 'How much is this?',
    'nasaan ang banyo?': 'Where is the bathroom?',
    'gutom na ako': 'I am hungry',
    'kailangan ko ng tulong': 'I need help',
    'paumanhin': 'Excuse me',
    'mahal kita': 'I love you',
    'ingat ka': 'Take care',
  },
  'en>es': {
    'hello': 'Hola',
    'thank you': 'Gracias',
    'thank you very much': 'Muchas gracias',
    'good morning': 'Buenos días',
    'how are you?': '¿Cómo estás?',
    'how much is this?': '¿Cuánto cuesta esto?',
    'where is the bathroom?': '¿Dónde está el baño?',
    'i need help': 'Necesito ayuda',
    'excuse me': 'Perdón',
  },
  'en>ja': {
    'hello': 'こんにちは',
    'thank you': 'ありがとう',
    'thank you very much': 'ありがとうございます',
    'good morning': 'おはようございます',
    'how are you?': 'お元気ですか？',
    'excuse me': 'すみません',
    'i need help': '助けが必要です',
  },
  'en>ko': {
    'hello': '안녕하세요',
    'thank you': '감사합니다',
    'good morning': '좋은 아침입니다',
    'how are you?': '어떻게 지내세요?',
    'please speak slowly': '천천히 말씀해 주세요',
    'excuse me': '실례합니다',
  },
  'en>fr': {
    'hello': 'Bonjour',
    'thank you': 'Merci',
    'thank you very much': 'Merci beaucoup',
    'good morning': 'Bonjour',
    'how are you?': 'Comment allez-vous ?',
    'excuse me': 'Excusez-moi',
  },
};
