import 'package:flutter_test/flutter_test.dart';
import 'package:thryve/core/utils/date_utils.dart';

void main() {
  group('DateKeys.addDays', () {
    test('steps by calendar day across month, year and leap boundaries', () {
      expect(
        DateKeys.of(DateKeys.addDays(DateTime(2026, 10, 31), 1)),
        '2026-11-01',
      );
      expect(
        DateKeys.of(DateKeys.addDays(DateTime(2026, 12, 31), 1)),
        '2027-01-01',
      );
      expect(
        DateKeys.of(DateKeys.addDays(DateTime(2028, 2, 28), 1)),
        '2028-02-29',
      );
      expect(
        DateKeys.of(DateKeys.addDays(DateTime(2026, 3), -1)),
        '2026-02-28',
      );
    });

    test('stays at midnight rather than drifting off the day boundary', () {
      // A 24-hour step would land on 23:00 or 01:00 wherever a DST transition
      // sits in between, which then double-counts one day and skips the next.
      for (int i = 0; i <= 400; i++) {
        final DateTime day = DateKeys.addDays(DateTime(2026), i);
        expect(day.hour, 0);
        expect(day.minute, 0);
      }
    });

    test('each step in a long run produces a distinct key', () {
      final Set<String> keys = <String>{
        for (int i = 0; i < 400; i++)
          DateKeys.of(DateKeys.addDays(DateTime(2026), i)),
      };
      expect(keys.length, 400);
    });
  });

  group('DateKeys.daysBetween', () {
    test('ignores the time of day', () {
      expect(
        DateKeys.daysBetween(
          DateTime(2026, 1, 1, 23, 59),
          DateTime(2026, 1, 3, 1),
        ),
        2,
      );
    });

    test('is negative when going back in time', () {
      expect(
        DateKeys.daysBetween(DateTime(2026, 3, 10), DateTime(2026, 3)),
        -9,
      );
    });

    test('counts a same-day pair as zero', () {
      expect(
        DateKeys.daysBetween(DateTime(2026, 5, 5, 6), DateTime(2026, 5, 5, 22)),
        0,
      );
    });
  });

  group('DateKeys.weekStart', () {
    test('is Monday at midnight for every day of the week', () {
      // 2026-01-05 is a Monday.
      for (int i = 0; i < 7; i++) {
        final DateTime day = DateKeys.addDays(DateTime(2026, 1, 5), i);
        final DateTime start = DateKeys.weekStart(day);
        expect(start.weekday, DateTime.monday);
        expect(start.hour, 0);
        expect(DateKeys.of(start), '2026-01-05');
      }
    });

    test('walks back across a month boundary', () {
      // 2026-11-01 is a Sunday, so its week starts the previous Monday.
      expect(DateKeys.of(DateKeys.weekStart(DateTime(2026, 11))), '2026-10-26');
    });
  });

  group('DateKeys.parse', () {
    test('round-trips a key', () {
      expect(DateKeys.of(DateKeys.parse('2026-10-05')), '2026-10-05');
    });
  });
}
