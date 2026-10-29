import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/data/models/models.dart';

import '../../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'ticking off every milestone does not finish a financial goal',
    () async {
      final Harness h = await Harness.onboarded();
      final Goal goal = h.goals.createGoal(
        title: 'Emergency fund',
        trackingType: GoalTrackingType.money,
        targetAmount: 5000,
      );

      final bool achieved = h.goals.saveMilestone(
        goal.id,
        title: 'Open the account',
        status: MilestoneStatus.completed,
      );

      expect(achieved, isFalse);
      expect(h.goals.goalById(goal.id)!.isAchieved, isFalse);

      // The target is still what finishes it.
      expect(h.goals.logEarnings(goal.id, 5000), isTrue);
      expect(h.goals.goalById(goal.id)!.isAchieved, isTrue);
    },
  );

  test('switching away from a money goal clears its saved amount', () async {
    final Harness h = await Harness.onboarded();
    final Goal goal = h.goals.createGoal(
      title: 'Emergency fund',
      trackingType: GoalTrackingType.money,
      targetAmount: 5000,
    );
    h.goals.logEarnings(goal.id, 3000);

    h.goals.updateGoal(
      goal.id,
      title: 'Emergency fund',
      trackingType: GoalTrackingType.progress,
      targetAmount: 0,
      why: '',
    );
    expect(h.goals.goalById(goal.id)!.currentAmount, 0);

    // Coming back with a lower target must not complete it on its own.
    final bool achieved = h.goals.updateGoal(
      goal.id,
      title: 'Emergency fund',
      trackingType: GoalTrackingType.money,
      targetAmount: 1000,
      why: '',
    );
    expect(achieved, isFalse);
    expect(h.goals.goalById(goal.id)!.isAchieved, isFalse);
  });

  test('goal edits survive a restart (regression)', () async {
    final Harness h = await Harness.onboarded();
    final String id = h.goals.focusGoal!.id;
    h.goals.updateGoal(
      id,
      title: 'Open a pottery studio',
      trackingType: GoalTrackingType.money,
      targetAmount: 80000,
      why: 'Independence',
    );

    final Harness restored = await h.restart();
    final Goal goal = restored.goals.goalById(id)!;
    expect(goal.title, 'Open a pottery studio');
    expect(goal.trackingType, GoalTrackingType.money);
    expect(goal.targetAmount, 80000);
  });

  test(
    'a goal with no milestones can be marked complete (regression)',
    () async {
      final Harness h = await Harness.onboarded();
      final String id = h.goals.focusGoal!.id;
      h.goals.setGoalCompleted(id, completed: true);
      expect(h.goals.goalById(id)!.isAchieved, isTrue);
      expect(h.goals.goalById(id)!.achievedAt, h.now);

      h.goals.setGoalCompleted(id, completed: false);
      expect(h.goals.goalById(id)!.isAchieved, isFalse);
    },
  );

  test(
    'completing every milestone achieves the goal and logs activity',
    () async {
      final Harness h = await Harness.onboarded();
      final String id = h.goals.focusGoal!.id;
      expect(
        h.goals.saveMilestone(
          id,
          title: 'Find a space',
          status: MilestoneStatus.pending,
        ),
        isFalse,
      );
      final String milestoneId = h.goals.goalById(id)!.milestones.single.id;

      final bool achieved = h.goals.saveMilestone(
        id,
        milestoneId: milestoneId,
        title: 'Find a space',
        status: MilestoneStatus.completed,
      );

      expect(achieved, isTrue);
      expect(h.goals.goalById(id)!.milestones.single.completedAt, h.now);
      expect(h.store.currentStreak, 1);
      expect(h.review().weekSummary.milestonesCompleted, 1);
      expect(h.review().weekSummary.goalsAchieved, 1);
      expect(h.goals.focusGoal, isNull);
    },
  );

  test('earnings complete a money goal when the target is reached', () async {
    final Harness h = await Harness.onboarded();
    final Goal goal = h.goals.createGoal(
      title: 'Emergency fund',
      trackingType: GoalTrackingType.money,
      targetAmount: 1000,
    );
    expect(h.goals.logEarnings(goal.id, 400), isFalse);
    expect(h.goals.logEarnings(goal.id, 600), isTrue);
    expect(h.goals.goalById(goal.id)!.currentAmount, 1000);
    expect(h.review().weekSummary.actions, 2);
  });

  test('all active goals are listed and focus can move', () async {
    final Harness h = await Harness.onboarded();
    final Goal second = h.goals.createGoal(
      title: 'Run a 10k',
      trackingType: GoalTrackingType.progress,
    );
    expect(h.goals.activeGoals, hasLength(2));
    expect(h.goals.focusGoal!.title, 'Build a studio');

    h.goals.setFocusGoal(second.id);
    expect(h.goals.focusGoal!.id, second.id);

    h.goals.deleteGoal(second.id);
    expect(h.goals.activeGoals, hasLength(1));
  });

  test('completed goals are listed newest first', () async {
    final Harness h = await Harness.onboarded();
    final Goal second = h.goals.createGoal(
      title: 'Run a 10k',
      trackingType: GoalTrackingType.progress,
    );
    h.goals.setGoalCompleted(second.id, completed: true);
    h.now = h.now.add(const Duration(days: 1));
    h.goals.setGoalCompleted(h.goals.activeGoals.single.id, completed: true);

    expect(h.goals.completedGoals.map((Goal g) => g.title), <String>[
      'Build a studio',
      'Run a 10k',
    ]);
  });

  test(
    'reopening a finished goal does not re-complete it (regression)',
    () async {
      final Harness h = await Harness.onboarded();
      final String id = h.goals.focusGoal!.id;
      h.goals.saveMilestone(
        id,
        title: 'Only step',
        status: MilestoneStatus.completed,
      );
      expect(h.goals.goalById(id)!.isAchieved, isTrue);

      h.goals.setGoalCompleted(id, completed: false);
      expect(h.goals.goalById(id)!.isAchieved, isFalse);

      // An unrelated edit must not flip it back to achieved.
      h.goals.updateGoal(
        id,
        title: 'Renamed',
        trackingType: GoalTrackingType.progress,
        targetAmount: 0,
        why: 'Still why',
      );
      expect(h.goals.goalById(id)!.isAchieved, isFalse);
      expect(h.goals.goalById(id)!.title, 'Renamed');
    },
  );

  test('levelUpGoal copies the goal and tolerates a missing id', () async {
    final Harness h = await Harness.onboarded();
    final Goal source = h.goals.focusGoal!;

    final Goal? next = h.goals.levelUpGoal(source.id);
    expect(next, isNotNull);
    expect(next!.title, 'Build a studio — Next Level');
    expect(h.goals.focusGoal!.id, next.id);

    expect(h.goals.levelUpGoal('missing'), isNull);
  });

  test(
    'consistency counts the longest streak while the goal was active',
    () async {
      final Harness h = await Harness.onboarded();
      final Goal goal = h.goals.focusGoal!;
      h.home.saveTask(title: 'Sketch');
      final String taskId = h.home.tasks.single.id;
      for (int day = 0; day < 3; day++) {
        h.home.toggleTask(taskId);
        h.now = h.now.add(const Duration(days: 1));
        h.store.refreshDay();
      }
      expect(h.goals.consistencyFor(goal), 3);
    },
  );
}
