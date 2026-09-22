import 'package:flutter/foundation.dart';

/// A language the app can translate to or from.
///
/// [code] is a Google Cloud Translation language code (for example, `tl`,
/// `pam`, or `ceb`) and is passed directly to the translation API.
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
  bool operator ==(Object other) => other is Language && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$name ($code)';
}
