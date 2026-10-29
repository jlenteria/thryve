import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thryve/core/motion/animated_reorder_column.dart';

void main() {
  Widget host(List<String> ids) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: AnimatedReorderColumn(
          ids: ids,
          itemBuilder: (BuildContext context, String id) => SizedBox(
            key: ValueKey<String>('box-$id'),
            height: 100,
            child: Text(id),
          ),
        ),
      ),
    ),
  );

  double top(WidgetTester tester, String id) =>
      tester.getTopLeft(find.byKey(ValueKey<String>('box-$id'))).dy;

  testWidgets('a reordered item starts where it was, then slides home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(<String>['a', 'b', 'c']));
    final double startTop = top(tester, 'c');

    await tester.pumpWidget(host(<String>['c', 'a', 'b']));
    // First frame after the change: still drawn at its old spot.
    expect(top(tester, 'c'), startTop);

    await tester.pump(const Duration(milliseconds: 300));
    final double midTop = top(tester, 'c');
    expect(midTop, lessThan(startTop));
    expect(midTop, greaterThan(top(tester, 'a') - 100));

    await tester.pumpAndSettle();
    expect(top(tester, 'c'), lessThan(top(tester, 'a')));
    expect(top(tester, 'a'), top(tester, 'c') + 100);
  });

  testWidgets('adding an item does not animate or throw', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(<String>['a', 'b']));
    await tester.pumpWidget(host(<String>['x', 'a', 'b']));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('x'), findsOneWidget);
  });
}
