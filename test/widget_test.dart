import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/app.dart';
import 'package:thryve/core/constants/app_constants.dart';
import 'package:thryve/core/widgets/buttons/primary_button.dart';
import 'package:thryve/data/models/models.dart';

import 'support/harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> setPhoneSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('completes onboarding and lands on Home', (
    WidgetTester tester,
  ) async {
    await setPhoneSize(tester);
    await tester.pumpWidget(const ThryveApp());
    await tester.pumpAndSettle();

    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
    await tester.enterText(find.byType(TextFormField).at(1), 'Build a studio');
    await tester.ensureVisible(find.text('Continue').first);
    await tester.tap(find.text('Continue').first);
    await tester.pumpAndSettle();

    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    await tester.ensureVisible(find.text('Skip for now'));
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('When will you grow?'), findsOneWidget);
    expect(find.text('Hey Alex, time to thryve 🌱'), findsOneWidget);
    await tester.ensureVisible(find.text("I'll set this later"));
    await tester.tap(find.text("I'll set this later"));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Alex.'), findsOneWidget);
    expect(find.text('Build a studio'), findsOneWidget);
    expect(find.text('0 days'), findsOneWidget);
  });

  testWidgets('step 1 shows validation instead of a dead button', (
    WidgetTester tester,
  ) async {
    await setPhoneSize(tester);
    await tester.pumpWidget(const ThryveApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue').first);
    await tester.tap(find.text('Continue').first);
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
  });

  testWidgets('every tab renders in dark mode without errors', (
    WidgetTester tester,
  ) async {
    await setPhoneSize(tester);
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.themeKey: ThemeMode.dark.name,
    });
    final Harness app = Harness();
    await app.store.load();
    await app.completeOnboarding();
    app.goals.createGoal(
      title: 'Emergency fund',
      trackingType: GoalTrackingType.money,
      targetAmount: 5000,
    );
    app.home.saveTask(title: 'Sketch');

    await tester.pumpWidget(ThryveApp(store: app.store));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.text('Hello, Alex.'));
    expect(Theme.of(context).brightness, Brightness.dark);

    for (final String tab in <String>['Goals', 'Wall', 'Review', 'Settings']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab tab');
    }
    expect(find.text('Shape your Thryve experience.'), findsOneWidget);
  });

  testWidgets('About, Privacy policy and Support open from Settings', (
    WidgetTester tester,
  ) async {
    await setPhoneSize(tester);
    PackageInfo.setMockInitialValues(
      appName: 'Thryve',
      packageName: 'com.bling.thryve',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final Harness app = Harness();
    await app.store.load();
    await app.completeOnboarding();

    await tester.pumpWidget(ThryveApp(store: app.store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    final Map<String, String> pages = <String, String>{
      'About Thryve': 'Version 1.0.0 (1)',
      'Privacy policy': 'Image links',
      'Support Thryve': 'Never required. Thank you for using Thryve!',
    };
    for (final MapEntry<String, String> page in pages.entries) {
      await tester.scrollUntilVisible(
        find.text(page.key),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text(page.key));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(page.value),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(page.value), findsOneWidget);
      expect(tester.takeException(), isNull, reason: page.key);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('primary button does not overflow in a narrow row', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 179,
              child: PrimaryButton(
                label: 'Log Earnings',
                icon: Icons.account_balance_wallet_outlined,
                onPressed: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Log Earnings'), findsOneWidget);
  });
}
