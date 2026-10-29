import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/motion/entrance.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/sheets.dart';
import '../../../core/widgets/thryve_card.dart';
import '../../../core/widgets/undo_snack.dart';
import '../../../data/models/models.dart';
import '../home_view_model.dart';
import 'practice_view_model.dart';

/// Today's daily practices with add / edit / remove.
class DisciplineCard extends StatelessWidget {
  const DisciplineCard({super.key});

  @override
  Widget build(BuildContext context) =>
      Consumer<HomeViewModel>(builder: _buildContent);

  Widget _buildContent(BuildContext context, HomeViewModel app, Widget? child) {
    final List<DisciplineTask> tasks = app.tasks;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return ThryveCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      // Rows opening and closing glide instead of snapping.
      child: AnimatedSize(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.standard,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.checklist_rtl, color: colors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Today's discipline", style: text.headlineSmall),
                ),
                IconButton(
                  tooltip: 'Add practice',
                  onPressed: () => _edit(context, app),
                  icon: const Icon(Icons.add),
                  color: colors.primary,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 12),
              child: tasks.isEmpty
                  ? Text(
                      'Add one small practice you can do every day.',
                      style: text.bodySmall,
                    )
                  : CountUp(
                      value: app.completedTasksToday.toDouble(),
                      duration: Motion.medium,
                      builder: (BuildContext context, double done) => Text(
                        '${done.round()} of ${tasks.length} complete today',
                        style: text.bodySmall,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            for (final DisciplineTask task in tasks)
              Entrance(
                key: ValueKey<String>(task.id),
                grow: true,
                offset: 8,
                child: _PracticeRow(
                  task: task,
                  onToggle: () {
                    Haptics.light();
                    app.toggleTask(task.id);
                  },
                  onEdit: () => _edit(context, app, task),
                  onDelete: () => _delete(context, app, task),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    HomeViewModel app, [
    DisciplineTask? task,
  ]) async {
    final String? title = await showThryveSheet<String>(
      context,
      (BuildContext context) => ChangeNotifierProvider<PracticeViewModel>(
        create: (_) => PracticeViewModel(initial: task?.title ?? ''),
        child: const _PracticeSheet(),
      ),
    );
    if (title != null) {
      app.saveTask(taskId: task?.id, title: title);
    }
  }

  void _delete(BuildContext context, HomeViewModel app, DisciplineTask task) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ({DisciplineTask task, int index})? removed = app.deleteTask(task.id);
    if (removed == null) {
      return;
    }
    showUndoSnack(
      messenger,
      message: 'Removed "${task.title}".',
      onUndo: () => app.restoreTask(removed.task, removed.index),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final DisciplineTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: CheckboxListTile(
            value: task.completed,
            onChanged: (_) => onToggle(),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            activeColor: colors.primary,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            title: AnimatedDefaultTextStyle(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.standard,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed
                    ? colors.onSurfaceVariant
                    : colors.onSurface,
              ),
              child: Text(task.title),
            ),
          ),
        ),
        PopupMenuButton<VoidCallback>(
          tooltip: 'Practice options',
          onSelected: (VoidCallback action) => action(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<VoidCallback>>[
            PopupMenuItem<VoidCallback>(
              value: onEdit,
              child: const Text('Edit'),
            ),
            PopupMenuItem<VoidCallback>(
              value: onDelete,
              child: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PracticeSheet extends StatelessWidget {
  const _PracticeSheet();

  @override
  Widget build(BuildContext context) =>
      Consumer<PracticeViewModel>(builder: _buildContent);

  Widget _buildContent(
    BuildContext context,
    PracticeViewModel vm,
    Widget? child,
  ) {
    void submit() {
      final String? title = vm.submit();
      if (title != null) {
        Navigator.pop(context, title);
      }
    }

    return ThryveBottomSheet(
      title: vm.isEditing ? 'Edit practice' : 'Add practice',
      content: TextField(
        controller: vm.title,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => submit(),
        decoration: const InputDecoration(
          labelText: 'Practice',
          hintText: 'e.g. 30 minutes of client outreach',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: submit, child: const Text('Save')),
      ],
    );
  }
}
