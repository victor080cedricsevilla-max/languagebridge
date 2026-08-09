import 'package:flutter/foundation.dart';

/// How a translation was captured. Drives the little badge on history rows.
enum TranslationSource {
  text('Text', 'text'),
  voice('Voice', 'voice'),
  camera('Camera', 'camera');

  const TranslationSource(this.label, this.id);
  final String label;
  final String id;
}

/// One entry in the user's translation history.
///
/// Immutable — edits go through [copyWith] so the UI always rebuilds off a new
/// instance. Mirrors the shape a Firestore document would take.
@immutable
class TranslationRecord {
  const TranslationRecord({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLangCode,
    required this.targetLangCode,
    required this.createdAt,
    this.source = TranslationSource.text,
    this.isFavorite = false,
  });

  final String id;
  final String sourceText;
  final String translatedText;
  final String sourceLangCode;
  final String targetLangCode;
  final DateTime createdAt;
  final TranslationSource source;
  final bool isFavorite;

  TranslationRecord copyWith({
    String? sourceText,
    String? translatedText,
    String? sourceLangCode,
    String? targetLangCode,
    DateTime? createdAt,
    TranslationSource? source,
    bool? isFavorite,
  }) {
    return TranslationRecord(
      id: id,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLangCode: sourceLangCode ?? this.sourceLangCode,
      targetLangCode: targetLangCode ?? this.targetLangCode,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Matches [query] against either side of the translation.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return sourceText.toLowerCase().contains(q) ||
        translatedText.toLowerCase().contains(q);
  }
}
