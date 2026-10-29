import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/data/models/models.dart';

import '../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a deleted goal comes back in its old position', () async {
    final Harness h = await Harness.onboarded();
    final Goal second = h.goals.createGoal(
      title: 'Run a 10k',
      trackingType: GoalTrackingType.progress,
    );
    h.goals.createGoal(title: 'Read', trackingType: GoalTrackingType.progress);

    final ({Goal goal, int index})? removed = h.goals.deleteGoal(
      second.id,
      keepImage: true,
    );
    expect(removed!.index, 1);
    expect(h.goals.goals.map((Goal g) => g.title), <String>[
      'Build a studio',
      'Read',
    ]);

    h.goals.restoreGoal(removed.goal, removed.index);
    expect(h.goals.goals.map((Goal g) => g.title), <String>[
      'Build a studio',
      'Run a 10k',
      'Read',
    ]);
  });

  test('deleting an unknown goal returns null', () async {
    final Harness h = await Harness.onboarded();
    expect(h.goals.deleteGoal('missing'), isNull);
  });

  test('a removed Wall item can be restored', () async {
    final Harness h = await Harness.onboarded();
    h.wall.addItem(title: 'A', category: 'Home', image: 'https://a.test/a');
    h.wall.addItem(title: 'B', category: 'Home', image: 'https://a.test/b');
    final String id = h.wall.items.first.id;

    final ({WallItem item, int index})? removed = h.wall.removeItem(
      id,
      keepImage: true,
    );
    expect(h.wall.items, hasLength(1));

    h.wall.restoreItem(removed!.item, removed.index);
    expect(h.wall.items.first.id, id);
    expect(h.wall.items, hasLength(2));
  });

  test('a removed practice keeps its checkmark when restored', () async {
    final Harness h = await Harness.onboarded();
    h.home.saveTask(title: 'Read');
    h.home.saveTask(title: 'Stretch');
    final String id = h.home.tasks.first.id;
    h.home.toggleTask(id);

    final ({DisciplineTask task, int index})? removed = h.home.deleteTask(id);
    expect(h.home.tasks.single.title, 'Stretch');

    h.home.restoreTask(removed!.task, removed.index);
    expect(h.home.tasks.first.title, 'Read');
    expect(h.home.tasks.first.completed, isTrue);
  });
}
