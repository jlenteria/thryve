import 'package:flutter/material.dart';

import '../../../core/motion/entrance.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/thryve_card.dart';
import '../../../data/models/models.dart';

/// Title, progress figure and bar for a goal. Used on Home and the Goals hub.
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.goal,
    this.label,
    this.onTap,
  });

  final Goal goal;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return ThryveCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (label != null) ...<Widget>[
                      SectionLabel(label!, color: colors.primary),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      goal.title,
                      style: text.headlineMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              CountUp(
                value: goal.isFinancial
                    ? goal.currentAmount
                    : goal.progressPercent.toDouble(),
                builder: (BuildContext context, double value) => Text(
                  goal.isFinancial
                      ? Formatters.money(goal.currencySymbol, value)
                      : '${value.round()}% complete',
                  style: text.headlineMedium?.copyWith(color: colors.primary),
                ),
              ),
              const Spacer(),
              if (goal.isFinancial)
                Text(
                  'of ${Formatters.money(goal.currencySymbol, goal.targetAmount)}',
                  style: text.labelMedium,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(progress: goal.progress),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(
                Icons.flag_outlined,
                size: 15,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  goal.milestones.isEmpty
                      ? 'No milestones yet — break it into steps'
                      : '${goal.completedMilestones}/${goal.milestones.length}'
                            ' milestones complete',
                  style: text.labelMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompletedGoalTile extends StatelessWidget {
  const CompletedGoalTile({super.key, required this.goal, required this.onTap});

  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DateTime completedAt = goal.achievedAt ?? goal.createdAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
        leading: CircleAvatar(
          backgroundColor: colors.primary,
          child: Icon(Icons.check, color: colors.onPrimary),
        ),
        title: Text(goal.title),
        subtitle: Text(
          'Completed ${Formatters.longDate(completedAt)} · '
          '${Formatters.plural(goal.daysActiveAt(completedAt), 'day')}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class MilestoneTile extends StatelessWidget {
  const MilestoneTile({
    super.key,
    required this.milestone,
    this.onTap,
    this.onDelete,
  });

  final Milestone milestone;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool isPending = milestone.status == MilestoneStatus.pending;
    final (
      IconData icon,
      Color background,
      Color foreground,
    ) = switch (milestone.status) {
      MilestoneStatus.completed => (
        Icons.check_circle,
        colors.primary,
        colors.onPrimary,
      ),
      MilestoneStatus.inProgress => (
        Icons.timelapse,
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      MilestoneStatus.pending => (
        Icons.schedule,
        colors.surfaceContainer,
        colors.onSurfaceVariant,
      ),
    };
    final String? subtitle =
        milestone.isCompleted && milestone.completedAt != null
        ? <String>[
            'Completed ${Formatters.shortDate(milestone.completedAt!)}',
            if (milestone.note != null) milestone.note!,
          ].join(' · ')
        : milestone.note;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isPending
            ? colors.surfaceContainerLow.withValues(alpha: 0.5)
            : colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        milestone.title,
                        style: text.titleMedium?.copyWith(
                          color: isPending
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle, style: text.bodySmall),
                    ],
                  ),
                ),
                if (milestone.valueLabel != null)
                  Text(
                    milestone.valueLabel!,
                    style: text.bodySmall?.copyWith(
                      color: milestone.isCompleted
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (onDelete != null)
                  PopupMenuButton<VoidCallback>(
                    tooltip: 'Milestone options',
                    onSelected: (VoidCallback action) => action(),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<VoidCallback>>[
                          if (onTap != null)
                            PopupMenuItem<VoidCallback>(
                              value: onTap,
                              child: const Text('Edit'),
                            ),
                          PopupMenuItem<VoidCallback>(
                            value: onDelete,
                            child: const Text('Delete'),
                          ),
                        ],
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
