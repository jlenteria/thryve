import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('changing the big dream renames the matching active goal', () async {
    final Harness h = await Harness.onboarded();
    await h.settings.updateProfile(
      name: 'Alex',
      dream: 'Run a pottery studio',
      anchor: 'My family',
    );
    expect(h.settings.user.bigDream, 'Run a pottery studio');
    expect(h.goals.focusGoal!.title, 'Run a pottery studio');
  });

  test('a renamed goal is left alone when the dream changes', () async {
    final Harness h = await Harness.onboarded();
    final String id = h.goals.focusGoal!.id;
    h.goals.setGoalCompleted(id, completed: true);

    await h.settings.updateProfile(
      name: 'Alex',
      dream: 'Something new',
      anchor: 'My family',
    );
    expect(h.goals.goalById(id)!.title, 'Build a studio');
  });

  test('profile edits are trimmed and persisted', () async {
    final Harness h = await Harness.onboarded();
    await h.settings.updateProfile(
      name: '  Sam ',
      dream: 'Build a studio',
      anchor: ' My dog ',
    );

    final Harness restored = await h.restart();
    expect(restored.settings.user.name, 'Sam');
    expect(restored.settings.user.anchor, 'My dog');
  });

  test('reminder time and switch are saved', () async {
    final Harness h = await Harness.onboarded();
    await h.settings.setReminderTime(const TimeOfDay(hour: 21, minute: 15));
    await h.settings.setNotificationsEnabled(false);

    final Harness restored = await h.restart();
    expect(
      restored.settings.user.reminderTime,
      const TimeOfDay(hour: 21, minute: 15),
    );
    expect(restored.settings.notificationsEnabled, isFalse);
  });

  test('reset returns to onboarding', () async {
    final Harness h = await Harness.onboarded();
    await h.settings.resetApp();
    expect(h.store.onboardingComplete, isFalse);
    expect(h.goals.goals, isEmpty);
  });
}
