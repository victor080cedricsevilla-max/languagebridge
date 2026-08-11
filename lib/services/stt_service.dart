import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-text wrapper.
///
/// Turns spoken words into text for the translator's input field. The device's
/// recognizer supports English and Filipino; for languages it doesn't have, it
/// falls back to its default locale rather than failing.
class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  /// App language code → device locale id.
  static const _locales = <String, String>{
    'en': 'en_US',
    'tl': 'fil_PH',
    'ceb': 'ceb_PH',
    'ilo': 'ilo_PH',
    'hil': 'hil_PH',
    'war': 'war_PH',
  };

  /// Initializes the recognizer (also prompts for the mic permission once).
  /// Returns `false` if speech recognition is unavailable on this device.
  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  bool get isListening => _speech.isListening;

  /// Starts listening; [onResult] fires with the recognized text as it updates
  /// (and again with `isFinal: true` when the phrase is complete).
  Future<bool> listen({
    required String langCode,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!await init()) return false;
    final localeId = await _resolveLocale(_locales[langCode] ?? 'en_US');
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
    return true;
  }

  /// Returns the device's matching locale id, or null to use its default.
  Future<String?> _resolveLocale(String preferred) async {
    final target = preferred.replaceAll('-', '_').toLowerCase();
    final locales = await _speech.locales();
    for (final l in locales) {
      if (l.localeId.replaceAll('-', '_').toLowerCase() == target) {
        return l.localeId;
      }
    }
    return null;
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
