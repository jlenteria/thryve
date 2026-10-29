import 'package:flutter/material.dart';

import '../../core/state/store_view_model.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/models.dart';

/// The weekly review: this week's summary, past reviews, and the form state
/// for this week's check-in (seeded from any saved review).
class WeeklyReviewViewModel extends StoreViewModel {
  WeeklyReviewViewModel(super.store)
    : _stars = _currentOf(store.state, store.clock)?.stars ?? 0,
      reflection = TextEditingController(
        text: _currentOf(store.state, store.clock)?.reflection ?? '',
      );

  final TextEditingController reflection;
  int _stars;

  @override
  List<Object?> watches(AppState state) => <Object?>[
    state.reviews,
    state.goals,
    state.activity,
    state.user,
  ];

  static WeeklyReview? _currentOf(AppState state, DateTime Function() clock) {
    final String key = DateKeys.weekKey(clock());
    for (final WeeklyReview review in state.reviews) {
      if (review.weekKey == key) {
        return review;
      }
    }
    return null;
  }

  // ── Read model ───────────────────────────────────────────────────

  Goal? get focusGoal => store.focusGoal;
  int get currentStreak => store.currentStreak;
  TimeOfDay get reminderTime => store.user.reminderTime;

  WeeklyReview? get currentReview => _currentOf(store.state, store.clock);

  List<WeeklyReview> get pastReviews {
    final String key = DateKeys.weekKey(now());
    final List<WeeklyReview> past = store.state.reviews
        .where((WeeklyReview review) => review.weekKey != key)
        .toList();
    past.sort(
      (WeeklyReview a, WeeklyReview b) => b.weekKey.compareTo(a.weekKey),
    );
    return past;
  }

  WeekSummary get weekSummary {
    final AppState state = store.state;
    final DateTime start = DateKeys.weekStart(now());
    final DateTime end = DateKeys.addDays(start, 7);
    bool inWeek(DateTime? date) =>
        date != null && !date.isBefore(start) && date.isBefore(end);

    int actions = 0;
    int activeDays = 0;
    for (int i = 0; i < 7; i++) {
      final int count =
          state.activity[DateKeys.of(DateKeys.addDays(start, i))] ?? 0;
      actions += count;
      if (count > 0) {
        activeDays++;
      }
    }
    int milestones = 0;
    for (final Goal goal in state.goals) {
      milestones += goal.milestones
          .where((Milestone m) => m.isCompleted && inWeek(m.completedAt))
          .length;
    }
    return WeekSummary(
      start: start,
      actions: actions,
      activeDays: activeDays,
      milestonesCompleted: milestones,
      goalsAchieved: state.goals
          .where((Goal goal) => inWeek(goal.achievedAt))
          .length,
    );
  }

  // ── Check-in form ────────────────────────────────────────────────

  int get stars => _stars;

  String get vibeLabel => WeeklyReview.vibeLabels[_stars];

  bool get isSaved => currentReview != null;

  void setStars(int value) {
    if (value < 1 || value > WeeklyReview.maxStars || value == _stars) {
      return;
    }
    _stars = value;
    notifyListeners();
  }

  /// Returns an error message, or null when saved.
  Future<String?> save() async {
    if (_stars == 0) {
      return 'Choose how the week felt first.';
    }
    if (isLoading) {
      return null;
    }
    startLoading();
    final String key = DateKeys.weekKey(now());
    final WeeklyReview review = WeeklyReview(
      weekKey: key,
      stars: _stars.clamp(1, WeeklyReview.maxStars),
      reflection: reflection.text.trim(),
      savedAt: now(),
    );
    try {
      await store.commit(
        store.state.copyWith(
          reviews: <WeeklyReview>[
            review,
            ...store.state.reviews.where((WeeklyReview r) => r.weekKey != key),
          ],
        ),
      );
      if (store.saveFailed) {
        return "We couldn't save your review. Tap Retry on the banner.";
      }
      return null;
    } finally {
      stopLoading();
    }
  }

  @override
  void dispose() {
    reflection.dispose();
    super.dispose();
  }
}
