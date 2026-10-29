import '../../core/state/store_view_model.dart';
import '../../core/utils/ids.dart';
import '../../data/models/models.dart';

/// What matters today: greeting, focus goal, streak, daily practices and the
/// featured Wall image.
class HomeViewModel extends StoreViewModel {
  HomeViewModel(super.store);

  @override
  List<Object?> watches(AppState state) => <Object?>[
    state.user,
    state.goals,
    state.tasks,
    state.wallItems,
    state.activity,
  ];

  // ── Read model ───────────────────────────────────────────────────

  UserProfile get user => store.user;
  Goal? get focusGoal => store.focusGoal;
  int get currentStreak => store.currentStreak;
  WallItem? get featuredWallItem => store.state.wallItems.featured;

  List<DisciplineTask> get tasks =>
      List<DisciplineTask>.unmodifiable(store.state.tasks);

  int get completedTasksToday =>
      store.state.tasks.where((DisciplineTask task) => task.completed).length;

  // ── Daily practices ──────────────────────────────────────────────

  void toggleTask(String id) {
    store.refreshDay();
    bool? nowCompleted;
    final List<DisciplineTask> tasks = store.state.tasks.map((
      DisciplineTask task,
    ) {
      if (task.id != id) {
        return task;
      }
      nowCompleted = !task.completed;
      return task.copyWith(completed: nowCompleted);
    }).toList();
    final bool? completed = nowCompleted;
    if (completed == null) {
      return;
    }
    store.commit(
      store.state.copyWith(
        tasks: tasks,
        activity: store.activityWith(completed ? 1 : -1),
      ),
    );
  }

  void saveTask({String? taskId, required String title}) {
    final String clean = title.trim();
    if (clean.isEmpty) {
      return;
    }
    final List<DisciplineTask> tasks = taskId == null
        ? <DisciplineTask>[
            ...store.state.tasks,
            DisciplineTask(id: Ids.next(), title: clean),
          ]
        : store.state.tasks
              .map(
                (DisciplineTask task) =>
                    task.id == taskId ? task.copyWith(title: clean) : task,
              )
              .toList();
    store.commit(store.state.copyWith(tasks: tasks));
  }

  /// Removes a practice and returns it with its position (for Undo), or
  /// null if it does not exist.
  ({DisciplineTask task, int index})? deleteTask(String id) {
    final int index = store.state.tasks.indexWhere(
      (DisciplineTask task) => task.id == id,
    );
    if (index < 0) {
      return null;
    }
    final DisciplineTask task = store.state.tasks[index];
    store.commit(
      store.state.copyWith(
        tasks: store.state.tasks
            .where((DisciplineTask other) => other.id != id)
            .toList(),
      ),
    );
    return (task: task, index: index);
  }

  /// Puts back a practice removed by [deleteTask].
  void restoreTask(DisciplineTask task, int index) {
    final List<DisciplineTask> tasks = List<DisciplineTask>.of(
      store.state.tasks,
    )..insert(index.clamp(0, store.state.tasks.length), task);
    store.commit(store.state.copyWith(tasks: tasks));
  }
}
