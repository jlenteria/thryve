import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/core/constants/app_constants.dart';
import 'package:thryve/core/state/store_view_model.dart';
import 'package:thryve/data/models/models.dart';
import 'package:thryve/data/repositories/app_state_repository.dart';

import '../support/harness.dart';

class _FailingRepository extends AppStateRepository {
  _FailingRepository({this.failLoad = false, this.failSave = false});

  final bool failLoad;
  bool failSave;

  @override
  Future<AppState> load() async {
    if (failLoad) {
      throw StateError('disk unavailable');
    }
    return const AppState();
  }

  @override
  Future<void> save(AppState state) async {
    if (failSave) {
      throw StateError('disk full');
    }
  }
}

/// Watches only the tasks slice, to test change filtering.
class _TasksOnly extends StoreViewModel {
  _TasksOnly(super.store);

  @override
  List<Object?> watches(AppState state) => <Object?>[state.tasks];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('new users start with no demo data', () async {
    final Harness h = Harness();
    await h.store.load();
    expect(h.store.onboardingComplete, isFalse);
    expect(h.goals.goals, isEmpty);
    expect(h.home.tasks, isEmpty);
    expect(h.wall.items, isEmpty);
    expect(h.store.user.avatar, isNull);
    expect(h.store.focusGoal, isNull);
  });

  test('a load failure is reported instead of spinning forever', () async {
    final Harness h = Harness(repository: _FailingRepository(failLoad: true));
    await h.store.load();
    expect(h.store.isLoaded, isFalse);
    expect(h.store.loadFailed, isTrue);
  });

  test('a save failure keeps the change and flags it, then recovers', () async {
    final _FailingRepository repository = _FailingRepository(failSave: true);
    final Harness h = Harness(repository: repository);
    await h.store.load();

    h.home.saveTask(title: 'Stretch');
    await h.store.flush();
    await Future<void>.delayed(Duration.zero);
    expect(h.home.tasks.single.title, 'Stretch');
    expect(h.store.saveFailed, isTrue);

    repository.failSave = false;
    h.home.saveTask(title: 'Read');
    await Future<void>.delayed(Duration.zero);
    expect(h.store.saveFailed, isFalse);
  });

  test('reset clears everything, including the corrupt backup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.corruptStateKey: '{old}',
    });
    final Harness h = await Harness.onboarded();
    await h.settings.resetApp();

    expect(h.store.onboardingComplete, isFalse);
    expect(h.goals.goals, isEmpty);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.corruptStateKey), isNull);

    final Harness restored = await h.restart();
    expect(restored.store.onboardingComplete, isFalse);
  });

  group('StoreViewModel', () {
    test('only notifies when a watched slice changes', () async {
      final Harness h = Harness();
      await h.store.load();
      final _TasksOnly viewModel = _TasksOnly(h.store);
      addTearDown(viewModel.dispose);
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      h.wall.addItem(title: 'A', category: 'Home', image: 'https://a.test/a');
      expect(notifications, 0, reason: 'Wall edits are not its business');

      h.home.saveTask(title: 'Sketch');
      expect(notifications, 1);
    });

    test('stops listening once disposed', () async {
      final Harness h = Harness();
      await h.store.load();
      final _TasksOnly viewModel = _TasksOnly(h.store);
      int notifications = 0;
      viewModel.addListener(() => notifications++);
      viewModel.dispose();

      h.home.saveTask(title: 'Sketch');
      expect(notifications, 0);
    });
  });

  test('day rollover clears practice checkmarks once per day', () async {
    final Harness h = await Harness.onboarded();
    h.home.saveTask(title: 'Sketch');
    h.home.toggleTask(h.home.tasks.single.id);
    expect(h.home.completedTasksToday, 1);

    h.store.refreshDay();
    expect(h.home.completedTasksToday, 1, reason: 'same day: unchanged');

    h.now = h.now.add(const Duration(days: 1));
    h.store.refreshDay();
    expect(h.home.completedTasksToday, 0);
  });

  test(
    'referenced images span profile, goals and Wall without repeats',
    () async {
      final Harness h = await Harness.onboarded();
      h.goals.createGoal(
        title: 'A',
        trackingType: GoalTrackingType.progress,
        image: 'local:shared.jpg',
      );
      h.wall.addItem(title: 'B', category: 'Home', image: 'local:shared.jpg');
      h.wall.addItem(title: 'C', category: 'Home', image: 'local:other.jpg');

      expect(h.store.referencedImages(), <String>{
        'local:shared.jpg',
        'local:other.jpg',
      });
    },
  );
}
