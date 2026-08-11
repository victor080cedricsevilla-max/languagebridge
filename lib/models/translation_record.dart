import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Builds a record from a Firestore document in a user's `history`
  /// subcollection. Missing fields fall back to safe defaults.
  factory TranslationRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return TranslationRecord(
      id: doc.id,
      sourceText: (data['sourceText'] as String?) ?? '',
      translatedText: (data['translatedText'] as String?) ?? '',
      sourceLangCode: (data['sourceLangCode'] as String?) ?? 'en',
      targetLangCode: (data['targetLangCode'] as String?) ?? 'en',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: TranslationSource.values.firstWhere(
        (s) => s.id == data['source'],
        orElse: () => TranslationSource.text,
      ),
      isFavorite: (data['isFavorite'] as bool?) ?? false,
    );
  }

  /// The fields written to Firestore. `createdAt` is stored as a concrete
  /// [Timestamp] (not a server value) so ordering is stable immediately.
  Map<String, dynamic> toMap() => {
        'sourceText': sourceText,
        'translatedText': translatedText,
        'sourceLangCode': sourceLangCode,
        'targetLangCode': targetLangCode,
        'createdAt': Timestamp.fromDate(createdAt),
        'source': source.id,
        'isFavorite': isFavorite,
      };
}
