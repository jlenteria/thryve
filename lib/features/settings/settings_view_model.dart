import 'package:flutter/material.dart';

import '../../core/services/image_store.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/reminder_sync.dart';
import '../../core/state/store_view_model.dart';
import '../../data/models/models.dart';

/// Profile, daily reminder and data reset.
class SettingsViewModel extends StoreViewModel {
  SettingsViewModel(super.store);

  @override
  List<Object?> watches(AppState state) => <Object?>[
    state.user,
    state.notificationsEnabled,
  ];

  // ── Read model ───────────────────────────────────────────────────

  UserProfile get user => store.user;
  bool get notificationsEnabled => store.state.notificationsEnabled;

  // ── Profile ──────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String name,
    required String dream,
    required String anchor,
  }) async {
    final bool copyChanged =
        name.trim() != user.name || anchor.trim() != (user.anchor ?? '');
    final String previousDream = user.bigDream ?? '';
    final String newDream = dream.trim();
    // The big dream is also the title of the goal created during
    // onboarding; keep the two in step while that goal is still active.
    final List<Goal>? goals = newDream.isNotEmpty && newDream != previousDream
        ? store.state.goals
              .map(
                (Goal goal) => !goal.isAchieved && goal.title == previousDream
                    ? goal.copyWith(title: newDream)
                    : goal,
              )
              .toList()
        : null;
    final Future<void> saved = store.commit(
      store.state.copyWith(
        goals: goals,
        user: user.copyWith(
          name: name.trim(),
          bigDream: newDream,
          anchor: anchor.trim(),
        ),
      ),
    );
    if (copyChanged) {
      await ReminderSync.apply(store.state);
    }
    await saved;
  }

  void setAvatar(String? ref) {
    final String? previous = user.avatar;
    store.commit(store.state.copyWith(user: user.copyWith(avatar: () => ref)));
    store.deleteImageIfUnreferenced(previous);
  }

  // ── Reminders ────────────────────────────────────────────────────

  Future<void> setReminderTime(TimeOfDay time) async {
    await store.commit(
      store.state.copyWith(user: user.copyWith(reminderTime: time)),
    );
    await ReminderSync.apply(store.state);
  }

  /// Turns the daily reminder on or off. Returns false only when turning it on
  /// was refused by the OS (permission denied), in which case nothing is saved
  /// and the switch stays where it was. A platform with no notification
  /// backend at all is not reported as blocked: it saves the preference and
  /// returns true, because no setting on the user's side can fix it.
  Future<bool> setNotificationsEnabled(bool enabled) async {
    // Enabling goes through the scheduler first: permission can be denied,
    // and nothing is saved until the nudge is actually scheduled.
    if (enabled &&
        await ReminderSync.apply(
              store.state.copyWith(notificationsEnabled: true),
              askExactAlarms: true,
            ) ==
            ReminderResult.denied) {
      return false;
    }
    // Re-read after the await: `apply` is a platform-channel round trip and a
    // day rollover can commit during it, so a pre-await snapshot would
    // overwrite that work.
    await store.commit(store.state.copyWith(notificationsEnabled: enabled));
    // Turning the switch off must also un-schedule the daily nudge; cancelling
    // the OS-level reminder only happens inside `apply`.
    if (!enabled) {
      await ReminderSync.apply(store.state);
    }
    return true;
  }

  // ── Data ─────────────────────────────────────────────────────────

  /// Removes every goal, practice, Wall item, review, image and reminder.
  /// The appearance choice belongs to the device, so it is kept.
  Future<void> resetApp() async {
    final Set<String> images = store.referencedImages();
    await NotificationService.cancelDaily();
    await store.reset();
    images.forEach(_deleteImage);
  }

  /// Deletes a stored image, best effort: the data is already gone, so a
  /// leftover file is harmless while a thrown error is not.
  void _deleteImage(String ref) {
    ImageStore.delete(ref).catchError((Object error) {
      debugPrint('Thryve: could not delete image ($error).');
    });
  }
}
