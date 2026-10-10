/// Requires two matching samples before translating, and suppresses duplicates.
class LiveTextFilter {
  String _candidate = '';
  String _emitted = '';

  String? add(String raw) {
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      _candidate = '';
      return null;
    }
    if (text != _candidate) {
      _candidate = text;
      return null;
    }
    if (text == _emitted) return null;
    _emitted = text;
    return text;
  }
}
