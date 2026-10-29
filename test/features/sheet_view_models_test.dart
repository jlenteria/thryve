import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/data/models/models.dart';
import 'package:thryve/features/goals/widgets/goal_form_sheet.dart';
import 'package:thryve/features/goals/widgets/goal_form_view_model.dart';
import 'package:thryve/features/goals/widgets/log_earnings_view_model.dart';
import 'package:thryve/features/goals/widgets/milestone_sheet.dart';
import 'package:thryve/features/goals/widgets/milestone_view_model.dart';
import 'package:thryve/features/home/widgets/practice_view_model.dart';
import 'package:thryve/features/onboarding/widgets/drum_picker.dart';
import 'package:thryve/features/wall/widgets/wall_editor_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('log earnings rejects bad amounts and accepts good ones', () {
    final LogEarningsViewModel vm = LogEarningsViewModel();
    addTearDown(vm.dispose);

    vm.amount.text = 'Infinity';
    expect(vm.submit(), isNull);
    expect(vm.error, isNotNull);

    vm.amount.text = '1,500';
    expect(vm.submit(), 1500);
    expect(vm.error, isNull);
  });

  test('practice sheet trims and rejects blank titles', () {
    final PracticeViewModel vm = PracticeViewModel(initial: 'Read');
    addTearDown(vm.dispose);
    expect(vm.isEditing, isTrue);

    vm.title.text = '  Read 10 pages ';
    expect(vm.submit(), 'Read 10 pages');
    vm.title.text = '   ';
    expect(vm.submit(), isNull);
  });

  test('wall editor needs a title and an image', () {
    final WallEditorViewModel vm = WallEditorViewModel();
    addTearDown(vm.dispose);

    expect(vm.submit(), isNull);
    expect(vm.error, isNotNull);

    vm.title.text = 'Lakehouse';
    vm.url.text = 'https://a.test/lake.jpg';
    final WallDraft draft = vm.submit()!;
    expect(draft.image, 'https://a.test/lake.jpg');
    expect(draft.category, WallEditorViewModel.categories.first);
  });

  test('wall editor keeps a custom legacy category selectable', () {
    final WallEditorViewModel vm = WallEditorViewModel(
      initial: const WallItem(
        id: '1',
        title: 'T',
        category: 'Old Custom',
        image: 'https://a.test/a.jpg',
      ),
    );
    addTearDown(vm.dispose);
    expect(vm.options, contains('Old Custom'));
    expect(vm.url.text, 'https://a.test/a.jpg');
  });

  test('milestone form switches status', () {
    final MilestoneViewModel vm = MilestoneViewModel();
    addTearDown(vm.dispose);
    expect(vm.status, MilestoneStatus.pending);
    vm.setStatus(MilestoneStatus.completed);
    expect(vm.status, MilestoneStatus.completed);
  });

  testWidgets('milestone form requires a title and returns a clean draft', (
    WidgetTester tester,
  ) async {
    MilestoneDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showMilestoneSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save milestone'));
    await tester.pumpAndSettle();
    expect(find.text('Name this milestone'), findsOneWidget);
    expect(
      result,
      isNull,
      reason: 'the sheet must not close on an invalid form',
    );

    await tester.enterText(find.byType(TextFormField).first, '  Ship v1  ');
    await tester.enterText(find.byType(TextFormField).at(1), '   ');
    await tester.tap(find.text('Save milestone'));
    await tester.pumpAndSettle();

    expect(result!.title, 'Ship v1');
    expect(result!.note, isNull);
    expect(result!.status, MilestoneStatus.pending);
  });

  testWidgets('drum picker syncs its wheel the short way round', (
    WidgetTester tester,
  ) async {
    final FixedExtentScrollController controller = DrumPicker.createController(
      value: 12,
      min: 1,
    );
    addTearDown(controller.dispose);
    int shown = 12;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrumPicker(
            controller: controller,
            value: shown,
            min: 1,
            max: 12,
            onChanged: (int v) => shown = v,
          ),
        ),
      ),
    );

    DrumPicker.syncTo(controller, value: 1, min: 1, max: 12);
    await tester.pumpAndSettle();
    // 12 -> 1 is one step forward around the loop, not eleven back.
    expect(controller.selectedItem, 12);
  });

  testWidgets('goal form validates, switches type and returns a draft', (
    WidgetTester tester,
  ) async {
    GoalDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showGoalForm(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create goal'));
    await tester.pumpAndSettle();
    expect(find.text('Give your goal a name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Emergency fund');
    await tester.tap(find.text('Money'));
    await tester.pumpAndSettle();
    expect(find.text('Target amount'), findsOneWidget);

    await tester.tap(find.text('Create goal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter an amount'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '5,000');
    await tester.tap(find.text('Create goal'));
    await tester.pumpAndSettle();

    expect(result!.title, 'Emergency fund');
    expect(result!.trackingType, GoalTrackingType.money);
    expect(result!.targetAmount, 5000);
  });

  test('goal form view model reflects the goal being edited', () {
    final GoalFormViewModel vm = GoalFormViewModel(
      initial: Goal(
        id: 'g',
        title: 'Fund',
        trackingType: GoalTrackingType.money,
        createdAt: DateTime(2026),
        targetAmount: 12000,
      ),
    );
    addTearDown(vm.dispose);
    expect(vm.isEditing, isTrue);
    expect(vm.isMoney, isTrue);
    expect(vm.target.text, '12,000');
  });
}
