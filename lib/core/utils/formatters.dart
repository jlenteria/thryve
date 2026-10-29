import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class Formatters {
  static final NumberFormat _amount = NumberFormat.decimalPattern('en_US');

  /// `12000` → `12,000`; keeps up to two decimals when they matter.
  static String amount(double value) {
    if (!value.isFinite) {
      return '0';
    }
    if (value == value.roundToDouble()) {
      return _amount.format(value.round());
    }
    return NumberFormat('#,##0.##', 'en_US').format(value);
  }

  static String money(String symbol, double value) => '$symbol${amount(value)}';

  /// Largest amount a user can enter. Keeps totals well inside the range
  /// where `double` is exact for whole numbers and JSON-safe.
  static const double maxAmount = 1e12;

  /// Snaps a value to whole cents. Money is held in a `double`, and adding
  /// decimal amounts drifts (ten `0.1` logs give `0.9999999999999999`), which
  /// would let a goal sit at 100% forever without ever reaching its target.
  static double roundToCents(double value) =>
      (value * 100).roundToDouble() / 100;

  /// Parses user-typed amounts like `5,000` or ` 12.5 `. Returns null when
  /// the text isn't a positive, finite number within [maxAmount].
  static double? parseAmount(String text) {
    final double? value = double.tryParse(text.replaceAll(',', '').trim());
    if (value == null || !value.isFinite || value <= 0 || value > maxAmount) {
      return null;
    }
    return roundToCents(value);
  }

  static String time(int hour, int minute) {
    final int h12 = hour % 12 == 0 ? 12 : hour % 12;
    final String period = hour < 12 ? 'AM' : 'PM';
    return '${h12.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  static String timeOfDay(TimeOfDay time) =>
      Formatters.time(time.hour, time.minute);

  static String plural(int count, String singular, [String? pluralForm]) =>
      '$count ${count == 1 ? singular : (pluralForm ?? '${singular}s')}';

  static String shortDate(DateTime date) => DateFormat('MMM d').format(date);

  static String longDate(DateTime date) => DateFormat('MMM d, y').format(date);
}
