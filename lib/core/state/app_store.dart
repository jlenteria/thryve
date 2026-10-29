import 'package:flutter/foundation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/app_state_repository.dart';
import '../constants/app_constants.dart';
import '../services/image_store.dart';
import '../utils/date_utils.dart';
import '../utils/streak_calculator.dart';

/// The single source of truth for persisted data.
///
/// The store owns loading, saving and the facts every feature needs (who the
/// user is, their goals, activity). It deliberately has no feature rules:
/// goals, practices, the Wall, settings and reviews each have their own view
/// model that reads from here and writes back through [commit].
class AppStore extends ChangeNotifier {
  AppStore({AppStateRepository? repository, this.clock = DateTime.now})
    : _repository = repository ?? AppStateRepository();

  final AppStateRepository _repository;

  /// Injectable for tests.
  final DateTime Function() clock;

  AppState _state = const AppState();
  bool _isLoaded = false;
  bool _loadFailed = false;
  bool _saveFailed = false;
  bool _isDisposed = false;

  // ── Read model ───────────────────────────────────────────────────

  AppState get state => _state;
  bool get isLoaded => _isLoaded;

  /// True when saved data couldn't be read at all (not merely corrupt), so
  /// the UI can offer a retry instead of an endless spinner.
  bool get loadFailed => _loadFailed;

  /// True when the most recent attempt to persist changes failed.
  bool get saveFailed => _saveFailed;

  bool get onboardingComplete => _state.onboardingComplete;
  UserProfile get user => _state.user;

  /// The goal shown on Home: the first active goal in the user's order.
  Goal? get focusGoal {
    for (final Goal goal in _state.goals) {
      if (!goal.isAchieved) {
        return goal;
      }
    }
    return null;
  }

  Goal? goalById(String id) {
    for (final Goal goal in _state.goals) {
      if (goal.id == id) {
        return goal;
      }
    }
    return null;
  }

  int get currentStreak =>
      StreakCalculator.current(_state.activity, now: clock());

  // ── Lifecycle ────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      _state = await _repository.load();
    } on Object catch (error) {
      debugPrint('Thryve: could not load saved state ($error).');
      _loadFailed = true;
      notifyListeners();
      return;
    }
    _loadFailed = false;
    _isLoaded = true;
    refreshDay();
    notifyListeners();
  }

  /// Resets today's practice checkmarks once the calendar day changes.
  /// Called on load and whenever the app returns to the foreground, so it
  /// runs regardless of which screen is open.
  void refreshDay() {
    final String today = DateKeys.today(clock());
    if (_state.tasksDay == today) {
      return;
    }
    commit(
      _state.copyWith(
        tasks: _state.tasks
            .map((DisciplineTask task) => task.copyWith(completed: false))
            .toList(),
        tasksDay: today,
      ),
    );
  }

  /// Tries again to write the current state after a failed save.
  Future<void> retrySave() => commit(_state);

  /// Completes once all pending changes are settled.
  Future<void> flush() => _repository.flush();

  /// Erases everything this store persisted and returns to a fresh state.
  Future<void> reset() async {
    await _repository.clear();
    // Stamp today: an untouchable `tasksDay` would make the minute-by-minute
    // rollover tick treat this empty state as a new day and immediately write
    // a partial document back, right after "delete everything".
    _state = const AppState().copyWith(tasksDay: DateKeys.today(clock()));
    _saveFailed = false;
    notifyListeners();
  }

  // ── Writing ──────────────────────────────────────────────────────

  /// Saves resolve after an await, so a late completion must not notify a
  /// store the widget tree already tore down.
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Applies [next] in memory immediately, then persists it. Never throws:
  /// a failed save sets [saveFailed] (so the UI can warn) and the next
  /// successful save clears it, since each save writes the full state.
  Future<void> commit(AppState next) async {
    _state = next;
    notifyListeners();
    try {
      await _repository.save(next);
      if (_saveFailed) {
        _saveFailed = false;
        notifyListeners();
      }
    } on Object catch (error) {
      debugPrint('Thryve: could not save state ($error).');
      if (!_saveFailed) {
        _saveFailed = true;
        notifyListeners();
      }
    }
  }

  /// Today's activity count adjusted by [delta], pruned to the retention
  /// window so the stored map stays small.
  Map<String, int> activityWith(int delta) {
    final DateTime now = clock();
    final String today = DateKeys.today(now);
    final String cutoff = DateKeys.of(
      now.subtract(const Duration(days: AppConstants.activityRetentionDays)),
    );
    final Map<String, int> activity = <String, int>{
      for (final MapEntry<String, int> entry in _state.activity.entries)
        if (entry.key.compareTo(cutoff) >= 0) entry.key: entry.value,
    };
    final int next = (activity[today] ?? 0) + delta;
    if (next > 0) {
      activity[today] = next;
    } else {
      activity.remove(today);
    }
    return activity;
  }

  // ── Images ───────────────────────────────────────────────────────

  /// Every image reference still used by the profile, goals or Wall.
  Set<String> referencedImages() => <String?>{
    _state.user.avatar,
    _state.user.anchorImage,
    ..._state.goals.map((Goal goal) => goal.image),
    ..._state.wallItems.map((WallItem item) => item.image),
  }.whereType<String>().where((String ref) => ref.isNotEmpty).toSet();

  /// Deletes a stored image file only if nothing else still points at it
  /// (a leveled-up goal shares its image with the goal it came from).
  void deleteImageIfUnreferenced(String? ref) {
    if (ref == null || referencedImages().contains(ref)) {
      return;
    }
    // Best effort: a leftover file is harmless, a thrown error is not.
    ImageStore.delete(ref).catchError((Object error) {
      debugPrint('Thryve: could not delete image ($error).');
    });
  }
}
