import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/data/models/models.dart';
import 'package:thryve/features/review/weekly_review_view_model.dart';

import '../../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> saveReview(
    Harness h, {
    required int stars,
    required String reflection,
  }) async {
    final WeeklyReviewViewModel vm = h.review();
    vm.setStars(stars);
    vm.reflection.text = reflection;
    await vm.save();
    vm.dispose();
  }

  test('reviews are kept per week', () async {
    final Harness h = await Harness.onboarded();
    await saveReview(h, stars: 4, reflection: 'Good start');
    expect(h.review().currentReview!.stars, 4);

    await saveReview(h, stars: 5, reflection: 'Even better');
    expect(h.review().currentReview!.reflection, 'Even better');
    expect(h.review().pastReviews, isEmpty);

    h.now = h.now.add(const Duration(days: 7));
    expect(h.review().currentReview, isNull);
    expect(h.review().pastReviews.single.stars, 5);
  });

  test('the form is seeded from the saved review', () async {
    final Harness h = await Harness.onboarded();
    await saveReview(h, stars: 3, reflection: 'Steady');

    final WeeklyReviewViewModel vm = h.review();
    addTearDown(vm.dispose);
    expect(vm.stars, 3);
    expect(vm.reflection.text, 'Steady');
    expect(vm.isSaved, isTrue);
  });

  test('saving without choosing stars asks first', () async {
    final Harness h = await Harness.onboarded();
    final WeeklyReviewViewModel vm = h.review();
    addTearDown(vm.dispose);

    expect(await vm.save(), isNotNull);
    expect(vm.isSaved, isFalse);
  });

  test('out-of-range stars are ignored', () async {
    final Harness h = await Harness.onboarded();
    final WeeklyReviewViewModel vm = h.review();
    addTearDown(vm.dispose);
    vm.setStars(42);
    vm.setStars(0);
    expect(vm.stars, 0);
  });

  test('the week summary counts actions and active days', () async {
    final Harness h = await Harness.onboarded();
    h.home.saveTask(title: 'Sketch');
    final String id = h.home.tasks.single.id;
    h.home.toggleTask(id);
    h.now = h.now.add(const Duration(days: 1));
    h.store.refreshDay();
    h.home.toggleTask(id);

    final WeekSummary week = h.review().weekSummary;
    expect(week.actions, 2);
    expect(week.activeDays, 2);
    expect(week.isEmpty, isFalse);
  });
}
