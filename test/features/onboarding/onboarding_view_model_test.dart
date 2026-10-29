import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/data/models/models.dart';
import 'package:thryve/features/onboarding/onboarding_view_model.dart';

import '../../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('creates the first goal from the dream and persists', () async {
    final Harness h = await Harness.onboarded();
    final Harness restored = await h.restart();

    expect(restored.store.onboardingComplete, isTrue);
    expect(restored.store.user.name, 'Alex');
    expect(
      restored.store.user.reminderTime,
      const TimeOfDay(hour: 7, minute: 30),
    );
    final Goal goal = restored.goals.goals.single;
    expect(goal.title, 'Build a studio');
    expect(goal.why, 'My family');
    expect(goal.trackingType, GoalTrackingType.progress);
  });

  test('financial-sounding dreams start as money goals', () async {
    final Harness h = await Harness.onboarded(dream: 'Earn ₱50k freelancing');
    expect(h.goals.focusGoal!.trackingType, GoalTrackingType.money);
  });

  test('matches whole words, so "Save the whales" is not money', () {
    expect(OnboardingViewModel.looksFinancial('Save the whales'), isFalse);
    expect(OnboardingViewModel.looksFinancial('Grow my income'), isTrue);
    expect(OnboardingViewModel.looksFinancial(r'Pay off $5,000'), isTrue);
    expect(OnboardingViewModel.looksFinancial('Run a 10k'), isFalse);
  });

  test('step 1 needs both a name and a dream', () async {
    final Harness h = Harness();
    await h.store.load();
    final OnboardingViewModel vm = OnboardingViewModel(h.store);
    addTearDown(vm.dispose);

    vm.continueFromStep1();
    expect(vm.currentStep, 0);
    expect(vm.showNameError, isTrue);
    expect(vm.showDreamError, isTrue);

    vm.nameController.text = 'Alex';
    vm.dreamController.text = 'Build a studio';
    expect(vm.isStep1Valid, isTrue);
  });

  test('12-hour picker values convert to the right 24-hour time', () async {
    final Harness h = Harness();
    final OnboardingViewModel vm = OnboardingViewModel(h.store);
    addTearDown(vm.dispose);

    vm.setReminderHour(12);
    vm.setAmPm(isAm: true);
    expect(vm.reminderTime.hour, 0);
    vm.setAmPm(isAm: false);
    expect(vm.reminderTime.hour, 12);
    vm.setReminderHour(7);
    expect(vm.reminderTime.hour, 19);
  });
}
