/// Small date helpers so the app stays dependency-free.
/// Swap for the `intl` package if localization becomes a requirement.
abstract final class DateFormats {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "just now", "12m ago", "5h ago", "Mar 14".
  static String relative(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(time);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(time);
  }

  /// "Mar 14" — or "Mar 14, 2025" when the year differs from [now].
  static String shortDate(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final base = '${_months[time.month - 1]} ${time.day}';
    return time.year == reference.year ? base : '$base, ${time.year}';
  }

  /// "March 14, 2026" — used on the profile card.
  static String longDate(DateTime time) {
    const full = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${full[time.month - 1]} ${time.day}, ${time.year}';
  }

  /// Header label for a history section: Today / Yesterday / This Week / date.
  static String groupLabel(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(reference.year, reference.month, reference.day);
    final delta = today.difference(day).inDays;

    if (delta <= 0) return 'Today';
    if (delta == 1) return 'Yesterday';
    if (delta < 7) return 'This Week';
    if (delta < 30) return 'This Month';
    return 'Earlier';
  }
}
