import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/entrance.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/thryve_card.dart';
import '../../core/widgets/thryve_page.dart';
import '../../data/models/models.dart';
import '../goals/goal_flows.dart';
import '../goals/widgets/goal_widgets.dart';
import '../shell/main_shell_view_model.dart';
import 'home_view_model.dart';
import 'widgets/discipline_card.dart';
import 'widgets/featured_wall_card.dart';

/// Answers "what matters today?": focus goal, daily practices and the
/// featured Wall reminder.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Consumer<HomeViewModel>(builder: _buildContent);

  Widget _buildContent(BuildContext context, HomeViewModel app, Widget? child) {
    final UserProfile user = app.user;
    final Goal? goal = app.focusGoal;
    final int streak = app.currentStreak;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ThryveTabPage(
      children: <Widget>[
        PageHeading(
          title: 'Hello, ${user.name.isEmpty ? 'friend' : user.name}.',
          subtitle: user.bigDream?.isNotEmpty == true
              ? 'Growing toward ${user.bigDream}'
              : null,
          trailing: Tooltip(
            message: 'Days in a row with at least one action',
            child: Pulse(
              trigger: streak,
              scale: 1.1,
              child: CountUp(
                value: streak.toDouble(),
                builder: (BuildContext context, double value) => Pill(
                  icon: Icons.local_fire_department,
                  label: Formatters.plural(value.round(), 'day'),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (user.anchor?.isNotEmpty == true) ...<Widget>[
          ThryveCard(
            key: const ValueKey<String>('anchor'),
            color: colors.primary.withValues(alpha: 0.07),
            child: Row(
              children: <Widget>[
                Icon(Icons.favorite_outline, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your anchor: ${user.anchor}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (goal == null)
          CalloutCard(
            icon: Icons.flag_outlined,
            title: 'Choose your next goal',
            message: 'Pick one meaningful thing to grow toward.',
            onTap: () => GoalFlows.create(context),
          )
        else
          GoalProgressCard(
            goal: goal,
            label: 'Focus goal',
            onTap: () => GoalFlows.openDetail(context, goal.id),
          ),
        const SizedBox(height: 16),
        const DisciplineCard(),
        const SizedBox(height: 16),
        FeaturedWallCard(
          item: app.featuredWallItem,
          onOpenWall: () => context.goToTab(ShellTab.wall),
        ),
      ],
    );
  }
}
