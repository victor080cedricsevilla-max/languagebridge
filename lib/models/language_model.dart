import 'package:flutter/foundation.dart';

/// A language-learning module bundled with the app (see `StarterModules`).
///
/// It is deliberately separate from [Language] in `models/language.dart`,
/// which is the translation language used by the translator UI.
@immutable
class LanguageModel {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;

  /// Lets a release hide a module without deleting its words.
  final bool isActive;
}
