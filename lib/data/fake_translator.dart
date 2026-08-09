import 'mock_data.dart';

/// The result of a prototype translation.
///
/// [isDemo] is true when the phrase was not in the local phrasebook — the UI
/// surfaces a small notice so nobody mistakes placeholder output for a real
/// translation.
class TranslationResult {
  const TranslationResult({required this.text, required this.isDemo});
  final String text;
  final bool isDemo;
}

/// Stand-in for the Translation API.
///
/// Looks the phrase up in [kPhrasebook] and otherwise returns clearly-labelled
/// placeholder text. Swap this class for a real HTTP client later — the screens
/// only depend on [translate]'s signature.
abstract final class FakeTranslator {
  /// Simulated network latency so loading states are visible in the demo.
  static const _latency = Duration(milliseconds: 700);

  static Future<TranslationResult> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    await Future<void>.delayed(_latency);

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const TranslationResult(text: '', isDemo: false);
    }

    if (from == to) {
      return TranslationResult(text: trimmed, isDemo: false);
    }

    final entries = kPhrasebook['$from>$to'];
    final hit = entries?[trimmed.toLowerCase()];
    if (hit != null) {
      return TranslationResult(text: hit, isDemo: false);
    }

    // Not in the phrasebook — return something shaped like a translation so
    // the layout can be judged, but flag it as demo output.
    final target = languageByCode(to);
    return TranslationResult(
      text: '[${target.name}] $trimmed',
      isDemo: true,
    );
  }
}
