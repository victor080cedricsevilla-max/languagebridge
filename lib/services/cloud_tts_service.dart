import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

/// Cloud text-to-speech via ElevenLabs.
///
/// Used only for the Philippine dialects that the phone has no on-device voice
/// for (Cebuano, Ilocano, Hiligaynon, Waray). English/Filipino still use the
/// free, instant on-device engine — see [TtsService].
///
/// The API key is injected at build/run time via
/// `--dart-define=ELEVENLABS_API_KEY=...`, so it never lives in source control.
class CloudTtsService {
  static const _apiKey = String.fromEnvironment('ELEVENLABS_API_KEY');

  /// "Sarah" — a default voice usable on the free tier. The multilingual model
  /// approximates the dialect pronunciation.
  static const _voiceId = 'EXAVITQu4vr4xnSDxMaL';
  static const _endpoint = 'https://api.elevenlabs.io/v1/text-to-speech';

  final AudioPlayer _player = AudioPlayer();

  /// Whether an ElevenLabs key was supplied at build time.
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Generates speech for [text] and plays it. Returns `false` on any failure
  /// (missing key, network error, quota, etc.) so the caller can show a message.
  Future<bool> speak(String text) async {
    if (!isConfigured || text.trim().isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint/$_voiceId'),
            headers: {
              'xi-api-key': _apiKey,
              'Content-Type': 'application/json',
              'Accept': 'audio/mpeg',
            },
            body: jsonEncode({
              'text': text,
              'model_id': 'eleven_multilingual_v2',
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) return false;
      await _player.stop();
      await _player.play(
        BytesSource(response.bodyBytes, mimeType: 'audio/mpeg'),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}
