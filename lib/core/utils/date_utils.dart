/// Calendar helpers. All keys are local-time `yyyy-MM-dd` strings so they sort
/// lexically and survive JSON round-trips without timezone drift.
abstract final class DateKeys {
  static String of(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String today([DateTime? now]) => of(now ?? DateTime.now());

  static DateTime parse(String key) {
    final List<String> parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Monday of the week containing [date], at midnight.
  static DateTime weekStart(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return addDays(day, -(day.weekday - DateTime.monday));
  }

  /// [date] shifted by whole calendar days, staying at midnight local.
  ///
  /// Deliberately not `add(Duration(days:))`: that steps 24 real hours, so
  /// across a DST boundary a 23 or 25 hour day drifts the cursor off midnight
  /// and eventually counts one day twice while skipping the next.
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static String weekKey([DateTime? now]) =>
      of(weekStart(now ?? DateTime.now()));

  /// Whole calendar days from [from] to [to], ignoring time of day.
  static int daysBetween(DateTime from, DateTime to) {
    final DateTime a = DateTime(from.year, from.month, from.day);
    final DateTime b = DateTime(to.year, to.month, to.day);
    // Compared as UTC midnights: local midnights can be 23 or 25 hours apart
    // across a DST boundary, which `difference.inDays` would round away.
    return DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
