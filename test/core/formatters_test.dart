import 'package:flutter_test/flutter_test.dart';
import 'package:thryve/core/utils/formatters.dart';

void main() {
  group('Formatters.parseAmount', () {
    test('accepts plain, comma-separated and decimal amounts', () {
      expect(Formatters.parseAmount('5,000'), 5000);
      expect(Formatters.parseAmount(' 12.5 '), 12.5);
      expect(Formatters.parseAmount('1000000'), 1000000);
    });

    test('rejects empty, non-numeric, zero and negative input', () {
      for (final String input in <String>['', 'abc', '0', '-5', '  ']) {
        expect(Formatters.parseAmount(input), isNull, reason: input);
      }
    });

    test('rejects non-finite and oversize values (regression)', () {
      for (final String input in <String>['Infinity', 'NaN', '1e400', '1e13']) {
        expect(Formatters.parseAmount(input), isNull, reason: input);
      }
      expect(
        Formatters.parseAmount('${Formatters.maxAmount.toInt()}'),
        Formatters.maxAmount,
      );
    });
  });

  group('Formatters.amount', () {
    test('formats whole numbers and keeps meaningful decimals', () {
      expect(Formatters.amount(12000), '12,000');
      expect(Formatters.amount(12.5), '12.5');
      expect(Formatters.amount(0), '0');
    });

    test('never throws on non-finite values (regression)', () {
      expect(Formatters.amount(double.infinity), '0');
      expect(Formatters.amount(double.negativeInfinity), '0');
      expect(Formatters.amount(double.nan), '0');
    });
  });

  test('time formats 12-hour clock with padding', () {
    expect(Formatters.time(0, 5), '12:05 AM');
    expect(Formatters.time(12, 0), '12:00 PM');
    expect(Formatters.time(19, 30), '07:30 PM');
  });

  test('plural only adds an s when the count is not one', () {
    expect(Formatters.plural(1, 'day'), '1 day');
    expect(Formatters.plural(2, 'day'), '2 days');
    expect(Formatters.plural(0, 'day'), '0 days');
  });
}
