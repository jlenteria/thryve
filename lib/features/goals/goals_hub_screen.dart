import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/entrance.dart';
import '../../core/motion/motion.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/thryve_card.dart';
import '../../core/widgets/thryve_page.dart';
import '../../data/models/models.dart';
import 'goal_flows.dart';
import 'goals_view_model.dart';
import 'widgets/goal_widgets.dart';

class GoalsHubScreen extends StatelessWidget {
  const GoalsHubScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Consumer<GoalsViewModel>(builder: _buildContent);

  Widget _buildContent(
    BuildContext context,
    GoalsViewModel app,
    Widget? child,
  ) {
    final List<Goal> active = app.activeGoals;
    final List<Goal> completed = app.completedGoals;
    final TextTheme text = Theme.of(context).textTheme;

    return ThryveTabPage(
      children: <Widget>[
        const PageHeading(
          title: 'Goals',
          subtitle: 'Turn what matters to you into small, visible progress.',
        ),
        const SizedBox(height: 24),
        Text('Active', style: text.titleLarge),
        const SizedBox(height: 10),
        if (active.isEmpty)
          CalloutCard(
            icon: Icons.flag_outlined,
            title: 'Nothing in progress',
            message: 'Start something meaningful — one goal is enough.',
            onTap: () => GoalFlows.create(context),
          )
        else
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.standard,
            alignment: Alignment.topCenter,
            child: Column(
              children: <Widget>[
                for (final (int index, Goal goal) in active.indexed)
                  Entrance(
                    key: ValueKey<String>(goal.id),
                    grow: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoalProgressCard(
                        goal: goal,
                        label: index == 0 ? 'Focus goal' : null,
                        onTap: () => GoalFlows.openDetail(context, goal.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        PrimaryButton(
          label: 'Add a goal',
          icon: Icons.add,
          onPressed: () => GoalFlows.create(context),
        ),
        const SizedBox(height: 28),
        Text('Completed', style: text.titleLarge),
        const SizedBox(height: 10),
        if (completed.isEmpty)
          Text(
            'Completed goals stay here as a record of your growth.',
            style: text.bodyMedium,
          )
        else
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.standard,
            alignment: Alignment.topCenter,
            child: Column(
              children: <Widget>[
                for (final Goal goal in completed)
                  Entrance(
                    key: ValueKey<String>(goal.id),
                    grow: true,
                    child: CompletedGoalTile(
                      goal: goal,
                      onTap: () => GoalFlows.openAchieved(context, goal.id),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
