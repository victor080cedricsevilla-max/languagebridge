import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech wrapper.
///
/// Speaks translated text in the target language when the device has a voice
/// for it. Philippine regional languages (Cebuano, Ilocano, …) usually have no
/// on-device voice, so [speak] returns `false` and the UI can say so instead of
/// failing silently.
class TtsService {
  TtsService() {
    _tts
      ..setSpeechRate(0.45)
      ..setVolume(1.0)
      ..setPitch(1.0);
  }

  final FlutterTts _tts = FlutterTts();

  /// App language code → BCP-47 TTS locale.
  static const _locales = <String, String>{
    'en': 'en-US',
    'tl': 'fil-PH', // Filipino
    'ceb': 'ceb-PH',
    'ilo': 'ilo-PH',
    'hil': 'hil-PH',
    'war': 'war-PH',
  };

  /// Whether the device has a voice for [langCode].
  Future<bool> isAvailable(String langCode) async {
    final locale = _locales[langCode] ?? langCode;
    try {
      final result = await _tts.isLanguageAvailable(locale);
      return result == true || result == 1;
    } catch (_) {
      return false;
    }
  }

  /// Speaks [text] in [langCode]. Returns `false` if no voice is available.
  Future<bool> speak(String text, String langCode) async {
    if (text.trim().isEmpty) return false;
    if (!await isAvailable(langCode)) return false;
    final locale = _locales[langCode] ?? langCode;
    await _tts.stop();
    await _tts.setLanguage(locale);
    await _tts.speak(text);
    return true;
  }

  Future<void> stop() => _tts.stop();

  void dispose() => _tts.stop();
}
