import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Raised for any translation failure (network, HTTP, or API error). Carries a
/// short, user-facing [message] the UI can show directly.
class TranslationException implements Exception {
  TranslationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Client for the Google Cloud Translation API (v2).
///
/// Does a single HTTP GET to the `translate` endpoint and returns the
/// translated text parsed from the JSON response. The API key is injected at
/// build/run time via `--dart-define=TRANSLATE_API_KEY=...`, so it never lives
/// in source control.
///
/// Language codes are Google's codes (e.g. `en`, `tl`, `ceb`, `ilo`, `hil`).
abstract final class TranslationApi {
  static const _endpoint =
      'https://translation.googleapis.com/language/translate/v2';

  static const _apiKey = String.fromEnvironment('TRANSLATE_API_KEY');

  /// Whether an API key was supplied at build time.
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Translates [text] from [from] to [to] and returns the translated string.
  /// Throws [TranslationException] on any network, HTTP, or API-level error.
  static Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    // Same language on both sides — nothing to call the API for.
    if (from == to) return trimmed;

    if (!isConfigured) {
      throw TranslationException(
        'No translation API key. Run the app with '
        '--dart-define=TRANSLATE_API_KEY=YOUR_KEY.',
      );
    }

    // HTTP GET with the query parameters Google Translate v2 expects.
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'key': _apiKey,
      'q': trimmed,
      'source': from,
      'target': to,
      'format': 'text',
    });

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } on SocketException {
      throw TranslationException(
        'No internet connection. Check your network and try again.',
      );
    } on HttpException {
      throw TranslationException('Could not reach the translation service.');
    } catch (_) {
      // TimeoutException and anything unexpected.
      throw TranslationException(
        'The translation service did not respond. Please try again.',
      );
    }

    if (response.statusCode != 200) {
      throw TranslationException(_errorMessage(response));
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw TranslationException('Received an invalid response from the server.');
    }

    final data = body['data'];
    final translations = (data is Map) ? data['translations'] : null;
    if (translations is List && translations.isNotEmpty) {
      final first = translations.first;
      final translated = (first is Map) ? first['translatedText'] : null;
      if (translated is String && translated.isNotEmpty) {
        return _unescape(translated);
      }
    }
    throw TranslationException('No translation was returned.');
  }

  /// Pulls Google's error message out of a non-200 response body.
  static String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      final message = (error is Map) ? error['message'] as String? : null;
      if (message != null && message.isNotEmpty) {
        return 'Translation failed: $message';
      }
    } catch (_) {
      // fall through to the generic message
    }
    return 'Translation service error (${response.statusCode}).';
  }

  /// Google returns a few HTML entities even in text mode; decode the common
  /// ones so results read cleanly.
  static String _unescape(String value) => value
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
