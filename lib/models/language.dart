import 'package:flutter/foundation.dart';

/// A language the app can translate to or from.
///
/// [code] follows ISO 639-1 so it maps straight onto the Google Cloud
/// Translation API when the backend is wired up.
@immutable
class Language {
  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;

  @override
  bool operator ==(Object other) =>
      other is Language && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$name ($code)';
}
