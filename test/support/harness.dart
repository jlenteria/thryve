import 'package:thryve/core/state/app_store.dart';
import 'package:thryve/data/repositories/app_state_repository.dart';
import 'package:thryve/features/goals/goals_view_model.dart';
import 'package:thryve/features/home/home_view_model.dart';
import 'package:thryve/features/onboarding/onboarding_view_model.dart';
import 'package:thryve/features/review/weekly_review_view_model.dart';
import 'package:thryve/features/settings/settings_view_model.dart';
import 'package:thryve/features/wall/wall_view_model.dart';

/// An [AppStore] with every feature view model on top of it, driven by a
/// movable clock. Mirrors how `ThryveApp` wires things together.
class Harness {
  Harness({AppStateRepository? repository, DateTime? start})
    : now = start ?? DateTime(2026, 10, 5, 9) {
    // 2026-10-05 is a Monday.
    store = AppStore(repository: repository, clock: () => now);
  }

  /// Moved by tests to simulate days passing.
  DateTime now;
  late final AppStore store;

  late final GoalsViewModel goals = GoalsViewModel(store);
  late final HomeViewModel home = HomeViewModel(store);
  late final WallViewModel wall = WallViewModel(store);
  late final SettingsViewModel settings = SettingsViewModel(store);

  /// Loads the store and runs onboarding through [OnboardingViewModel].
  static Future<Harness> onboarded({
    String dream = 'Build a studio',
    DateTime? start,
  }) async {
    final Harness harness = Harness(start: start);
    await harness.store.load();
    await harness.completeOnboarding(dream: dream);
    return harness;
  }

  Future<void> completeOnboarding({
    String name = 'Alex',
    String dream = 'Build a studio',
    String anchor = 'My family',
  }) async {
    final OnboardingViewModel onboarding = OnboardingViewModel(store);
    onboarding.nameController.text = name;
    onboarding.dreamController.text = dream;
    onboarding.anchorController.text = anchor;
    onboarding.setReminderHour(7);
    onboarding.setReminderMinute(30);
    onboarding.setAmPm(isAm: true);
    await onboarding.complete(enableReminders: false);
    onboarding.dispose();
  }

  WeeklyReviewViewModel review() => WeeklyReviewViewModel(store);

  /// A fresh app instance reading what the previous one saved.
  Future<Harness> restart() async {
    await store.flush();
    final Harness next = Harness(start: now);
    await next.store.load();
    return next;
  }
}
