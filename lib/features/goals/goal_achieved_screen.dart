import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/confetti.dart';
import '../../core/motion/entrance.dart';
import '../../core/motion/motion.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/thryve_card.dart';
import '../../data/models/models.dart';
import 'goal_flows.dart';
import 'goals_view_model.dart';

class GoalAchievedScreen extends StatelessWidget {
  const GoalAchievedScreen({
    super.key,
    required this.goalId,
    this.celebrate = false,
  });

  final String goalId;

  /// Rain confetti when the goal was only just completed.
  final bool celebrate;

  void _backToRoot(BuildContext context) =>
      Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);

  @override
  Widget build(BuildContext context) =>
      Consumer<GoalsViewModel>(builder: _buildContent);

  Widget _buildContent(
    BuildContext context,
    GoalsViewModel app,
    Widget? child,
  ) {
    final Goal? goal = app.goalById(goalId);
    if (goal == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int consistency = app.consistencyFor(goal);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _content(context, app, goal, consistency)),
          if (celebrate)
            Positioned.fill(
              child: ConfettiBurst(
                colors: <Color>[
                  colors.primary,
                  colors.primaryContainer,
                  colors.tertiary,
                  colors.secondary,
                  Colors.amber,
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    GoalsViewModel app,
    Goal goal,
    int consistency,
  ) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: Motion.of(context, const Duration(milliseconds: 700)),
              curve: Motion.bouncy,
              builder: (BuildContext context, double scale, Widget? child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer.withValues(alpha: 0.25),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 60,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Entrance(
            delay: Entrance.stagger(1),
            child: Text(
              'GOAL ACHIEVED',
              textAlign: TextAlign.center,
              style: text.labelMedium?.copyWith(
                color: colors.primary,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Entrance(
            delay: Entrance.stagger(2),
            child: Text(
              goal.title,
              textAlign: TextAlign.center,
              style: text.displayMedium,
            ),
          ),
          if (goal.why?.isNotEmpty == true) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'You did this for ${goal.why}.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Entrance(
            delay: Entrance.stagger(4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: goal.isFinancial
                        ? Icons.account_balance_wallet_outlined
                        : Icons.flag_outlined,
                    label: goal.isFinancial ? 'Earned' : 'Milestones',
                    value: goal.isFinancial
                        ? Formatters.money(
                            goal.currencySymbol,
                            goal.currentAmount,
                          )
                        : '${goal.completedMilestones}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Time taken',
                    value: Formatters.plural(
                      goal.daysActiveAt(app.clock()),
                      'day',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Entrance(
            delay: Entrance.stagger(5),
            child: _StatCard(
              icon: Icons.local_fire_department,
              label: 'Best streak',
              value: consistency == 0
                  ? 'Every step counted'
                  : '${Formatters.plural(consistency, 'day')} in a row',
              horizontal: true,
            ),
          ),
          if (goal.image != null) ...<Widget>[
            const SizedBox(height: 12),
            AppImage(
              source: goal.image,
              semanticLabel: 'Image for ${goal.title}',
              height: 160,
              width: double.infinity,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Level up this goal',
            icon: Icons.trending_up,
            onPressed: () {
              app.levelUpGoal(goal.id);
              _backToRoot(context);
            },
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Start a new goal',
            icon: Icons.add,
            onPressed: () async {
              final Goal? created = await GoalFlows.create(context);
              if (created != null && context.mounted) {
                app.setFocusGoal(created.id);
                _backToRoot(context);
              }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _backToRoot(context),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.horizontal = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final List<Widget> labelAndValue = <Widget>[
      Text(label.toUpperCase(), style: text.labelSmall),
      const SizedBox(height: 4),
      Text(
        value,
        style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        textAlign: horizontal ? TextAlign.start : TextAlign.center,
      ),
    ];
    return ThryveCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: horizontal
          ? Row(
              children: <Widget>[
                Icon(icon, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: labelAndValue,
                  ),
                ),
              ],
            )
          : Column(
              children: <Widget>[
                Icon(icon, color: colors.primary),
                const SizedBox(height: 8),
                ...labelAndValue,
              ],
            ),
    );
  }
}
