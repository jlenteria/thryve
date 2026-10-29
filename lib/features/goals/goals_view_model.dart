import '../../core/state/store_view_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/streak_calculator.dart';
import '../../data/models/models.dart';

/// Goals and milestones: the hub, detail and achievement screens.
class GoalsViewModel extends StoreViewModel {
  GoalsViewModel(super.store);

  @override
  List<Object?> watches(AppState state) => <Object?>[state.goals];

  /// For screens that need "today" in the app's own clock.
  DateTime Function() get clock => store.clock;

  // ── Read model ───────────────────────────────────────────────────

  List<Goal> get goals => List<Goal>.unmodifiable(store.state.goals);

  List<Goal> get activeGoals =>
      store.state.goals.where((Goal goal) => !goal.isAchieved).toList();

  List<Goal> get completedGoals {
    final List<Goal> done = store.state.goals
        .where((Goal goal) => goal.isAchieved)
        .toList();
    DateTime completedAt(Goal goal) => goal.achievedAt ?? goal.createdAt;
    done.sort((Goal a, Goal b) => completedAt(b).compareTo(completedAt(a)));
    return done;
  }

  /// The goal shown on Home: the first active goal in the user's order.
  Goal? get focusGoal => store.focusGoal;

  Goal? goalById(String id) => store.goalById(id);

  /// Longest streak while the goal was active, for the achievement screen.
  int consistencyFor(Goal goal) => StreakCalculator.longest(
    store.state.activity,
    from: goal.createdAt,
    to: goal.achievedAt ?? now(),
  );

  // ── Goals ────────────────────────────────────────────────────────

  Goal createGoal({
    required String title,
    required GoalTrackingType trackingType,
    double targetAmount = 0,
    String why = '',
    String? image,
    bool atFront = false,
  }) {
    final Goal goal = Goal(
      id: Ids.next(),
      title: title.trim(),
      trackingType: trackingType,
      createdAt: now(),
      targetAmount: trackingType == GoalTrackingType.money ? targetAmount : 0,
      why: why.trim().isEmpty ? null : why.trim(),
      image: image,
    );
    store.commit(
      store.state.copyWith(
        goals: atFront
            ? <Goal>[goal, ...store.state.goals]
            : <Goal>[...store.state.goals, goal],
      ),
    );
    return goal;
  }

  /// Returns true if this edit completed the goal (e.g. target lowered
  /// below the amount already saved).
  bool updateGoal(
    String id, {
    required String title,
    required GoalTrackingType trackingType,
    required double targetAmount,
    required String why,
  }) => _updateGoal(
    id,
    (Goal goal) => goal.copyWith(
      title: title.trim(),
      trackingType: trackingType,
      targetAmount: trackingType == GoalTrackingType.money ? targetAmount : 0,
      // A goal leaving the money track keeps its saved amount, and switching
      // back with a lower target would then complete it on its own.
      currentAmount: trackingType == GoalTrackingType.money
          ? goal.currentAmount
          : 0,
      why: why.trim(),
    ),
  );

  /// Removes a goal and returns it with its position, or null if it does
  /// not exist. Pass [keepImage] to offer Undo: the image file then stays
  /// until [discardImage] is called.
  ({Goal goal, int index})? deleteGoal(String id, {bool keepImage = false}) {
    final int index = store.state.goals.indexWhere((Goal g) => g.id == id);
    if (index < 0) {
      return null;
    }
    final Goal goal = store.state.goals[index];
    store.commit(
      store.state.copyWith(
        goals: store.state.goals.where((Goal g) => g.id != id).toList(),
      ),
    );
    if (!keepImage) {
      store.deleteImageIfUnreferenced(goal.image);
    }
    return (goal: goal, index: index);
  }

  /// Puts back a goal removed by [deleteGoal].
  void restoreGoal(Goal goal, int index) {
    final List<Goal> goals = List<Goal>.of(store.state.goals)
      ..insert(index.clamp(0, store.state.goals.length), goal);
    store.commit(store.state.copyWith(goals: goals));
  }

  /// Finishes a delete that was kept undoable.
  void discardImage(String? ref) => store.deleteImageIfUnreferenced(ref);

  /// Moves a goal to the front so it becomes the Home focus.
  void setFocusGoal(String id) {
    final Goal? goal = goalById(id);
    if (goal == null) {
      return;
    }
    store.commit(
      store.state.copyWith(
        goals: <Goal>[goal, ...store.state.goals.where((Goal g) => g.id != id)],
      ),
    );
  }

  void setGoalCompleted(String id, {required bool completed}) {
    final Goal? goal = goalById(id);
    if (goal == null || goal.isAchieved == completed) {
      return;
    }
    final List<Goal> goals = store.state.goals
        .map(
          (Goal goal) => goal.id == id
              ? goal.copyWith(achievedAt: () => completed ? now() : null)
              : goal,
        )
        .toList();
    store.commit(
      store.state.copyWith(
        goals: goals,
        activity: store.activityWith(completed ? 1 : -1),
      ),
    );
  }

  /// Adds [amount] to a financial goal. Returns true if this completed it.
  bool logEarnings(String id, double amount) {
    if (amount <= 0) {
      return false;
    }
    return _updateGoal(
      id,
      (Goal goal) => goal.copyWith(
        currentAmount: Formatters.roundToCents(goal.currentAmount + amount),
      ),
      activity: 1,
    );
  }

  /// Starts a follow-up goal of the same kind with a doubled target, or
  /// returns null if [id] no longer exists.
  Goal? levelUpGoal(String id) {
    final Goal? source = goalById(id);
    if (source == null) {
      return null;
    }
    return createGoal(
      title: '${source.title} — Next Level',
      trackingType: source.trackingType,
      targetAmount: source.targetAmount * 2,
      why: source.why ?? '',
      image: source.image,
      atFront: true,
    );
  }

  // ── Milestones ───────────────────────────────────────────────────

  /// Adds or updates a milestone. Returns true if this completed the goal.
  bool saveMilestone(
    String goalId, {
    String? milestoneId,
    required String title,
    required MilestoneStatus status,
    String? note,
    String? valueLabel,
  }) {
    final Goal? goal = goalById(goalId);
    if (goal == null || title.trim().isEmpty) {
      return false;
    }
    Milestone? previous;
    for (final Milestone m in goal.milestones) {
      if (m.id == milestoneId) {
        previous = m;
      }
    }
    final bool newlyCompleted =
        status == MilestoneStatus.completed && previous?.isCompleted != true;
    String? clean(String? value) =>
        value == null || value.trim().isEmpty ? null : value.trim();
    final Milestone value = Milestone(
      id: previous?.id ?? Ids.next(),
      title: title.trim(),
      status: status,
      note: clean(note),
      valueLabel: clean(valueLabel),
      completedAt: status == MilestoneStatus.completed
          ? (previous?.completedAt ?? now())
          : null,
    );
    return _updateGoal(
      goalId,
      activity: newlyCompleted ? 1 : 0,
      (Goal g) => g.copyWith(
        milestones: previous == null
            ? <Milestone>[...g.milestones, value]
            : g.milestones
                  .map((Milestone m) => m.id == milestoneId ? value : m)
                  .toList(),
      ),
    );
  }

  void deleteMilestone(String goalId, String milestoneId) {
    // Removing the last unfinished milestone is not progress: without this
    // the goal would quietly mark itself achieved on a deletion.
    _updateGoal(
      goalId,
      autoComplete: false,
      (Goal goal) => goal.copyWith(
        milestones: goal.milestones
            .where((Milestone m) => m.id != milestoneId)
            .toList(),
      ),
    );
  }

  /// Applies [change] and auto-completes the goal when its milestones or
  /// target are reached. Returns true if the goal became achieved.
  bool _updateGoal(
    String id,
    Goal Function(Goal) change, {
    int activity = 0,
    bool autoComplete = true,
  }) {
    bool achieved = false;
    final List<Goal> goals = store.state.goals.map((Goal goal) {
      if (goal.id != id) {
        return goal;
      }
      Goal updated = change(goal);
      // Only complete the goal when this change is what reached the finish
      // line. Otherwise reopening a goal whose milestones are all done would
      // re-complete it on the next unrelated edit.
      // Milestones are optional scaffolding on a financial goal, so ticking
      // them all off must not finish it: only the target does.
      final bool milestonesFinished =
          !updated.isFinancial &&
          !goal.allMilestonesComplete &&
          updated.allMilestonesComplete;
      final bool reachedNow =
          milestonesFinished || (!goal.targetReached && updated.targetReached);
      if (autoComplete && !updated.isAchieved && reachedNow) {
        updated = updated.copyWith(achievedAt: now);
        achieved = true;
      }
      return updated;
    }).toList();
    store.commit(
      store.state.copyWith(
        goals: goals,
        activity: activity != 0 ? store.activityWith(activity) : null,
      ),
    );
    return achieved;
  }
}
