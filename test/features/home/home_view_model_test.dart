import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/data/models/models.dart';

import '../../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('practices build a streak and reset on a new day', () async {
    final Harness h = await Harness.onboarded();
    h.home.saveTask(title: 'Sketch for 20 minutes');
    final String taskId = h.home.tasks.single.id;

    h.home.toggleTask(taskId);
    expect(h.home.completedTasksToday, 1);
    expect(h.home.currentStreak, 1);

    // Unchecking undoes today's activity.
    h.home.toggleTask(taskId);
    expect(h.home.currentStreak, 0);
    h.home.toggleTask(taskId);

    h.now = h.now.add(const Duration(days: 1));
    h.store.refreshDay();
    expect(h.home.completedTasksToday, 0);
    expect(h.home.currentStreak, 1, reason: "yesterday's streak still counts");

    h.home.toggleTask(taskId);
    expect(h.home.currentStreak, 2);
  });

  test('blank practice titles are ignored; edits and deletes stick', () async {
    final Harness h = await Harness.onboarded();
    h.home.saveTask(title: '   ');
    expect(h.home.tasks, isEmpty);

    h.home.saveTask(title: 'Read');
    final String id = h.home.tasks.single.id;
    h.home.saveTask(taskId: id, title: 'Read 10 pages');
    expect(h.home.tasks.single.title, 'Read 10 pages');

    h.home.deleteTask(id);
    expect(h.home.tasks, isEmpty);
  });

  test('toggling an unknown practice changes nothing', () async {
    final Harness h = await Harness.onboarded();
    h.home.toggleTask('missing');
    expect(h.home.currentStreak, 0);
  });

  test('Home features the pinned Wall item', () async {
    final Harness h = await Harness.onboarded();
    expect(h.home.featuredWallItem, isNull);

    h.wall.addItem(title: 'A', category: 'Home', image: 'https://a.test/a');
    h.wall.addItem(title: 'B', category: 'Home', image: 'https://a.test/b');
    expect(h.home.featuredWallItem!.title, 'B', reason: 'newest first');

    final WallItem a = h.wall.items.firstWhere((WallItem i) => i.title == 'A');
    h.wall.togglePinned(a.id);
    expect(h.home.featuredWallItem!.title, 'A');
  });
}
