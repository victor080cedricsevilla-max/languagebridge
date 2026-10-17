import 'package:flutter/foundation.dart';

/// One dictionary entry of a bundled language module.
///
/// [languageId] links the entry back to its [LanguageModel].
@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.languageId,
    required this.title,
    required this.description,
    required this.category,
    required this.content,
    required this.translation,
    required this.pronunciation,
    this.meaning = '',
    this.sourceUrl = '',
  });

  /// Stable across releases, e.g. `starter-ceb-water`.
  final String id;
  final String languageId;
  final String title;
  final String description;
  final String category;
  final String content;
  final String translation;
  final String pronunciation;
  final String meaning;
  final String sourceUrl;
}
