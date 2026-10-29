import 'date_utils.dart';

/// Derives streak numbers from a per-day activity log (`yyyy-MM-dd` → count).
abstract final class StreakCalculator {
  /// Consecutive active days ending today. If today has no activity yet the
  /// streak still counts through yesterday, so it doesn't reset at midnight.
  static int current(Map<String, int> activity, {DateTime? now}) {
    final DateTime today = now ?? DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);
    if (!_isActive(activity, cursor)) {
      cursor = DateKeys.addDays(cursor, -1);
    }
    int streak = 0;
    while (_isActive(activity, cursor)) {
      streak++;
      cursor = DateKeys.addDays(cursor, -1);
    }
    return streak;
  }

  /// Longest run of consecutive active days within [from]..[to] inclusive.
  static int longest(
    Map<String, int> activity, {
    required DateTime from,
    required DateTime to,
  }) {
    int best = 0;
    int run = 0;
    DateTime cursor = DateTime(from.year, from.month, from.day);
    final DateTime end = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(end)) {
      run = _isActive(activity, cursor) ? run + 1 : 0;
      if (run > best) {
        best = run;
      }
      cursor = DateKeys.addDays(cursor, 1);
    }
    return best;
  }

  static bool _isActive(Map<String, int> activity, DateTime day) =>
      (activity[DateKeys.of(day)] ?? 0) > 0;
}
