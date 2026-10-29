import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/motion.dart';
import '../../data/models/models.dart';
import 'goal_achieved_screen.dart';
import 'goal_detail_screen.dart';
import 'goals_view_model.dart';
import 'widgets/goal_form_sheet.dart';

/// Navigation flows shared by Home, the Goals hub and the detail screens.
abstract final class GoalFlows {
  static Future<void> openDetail(BuildContext context, String goalId) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GoalDetailScreen(goalId: goalId),
        ),
      );

  /// [celebrate] plays the confetti; leave it off when merely revisiting a
  /// goal finished earlier.
  static Future<void> openAchieved(
    BuildContext context,
    String goalId, {
    bool celebrate = false,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GoalAchievedScreen(goalId: goalId, celebrate: celebrate),
    ),
  );

  /// Shows the celebration screen when an action just completed a goal.
  static Future<void> celebrateIf(
    BuildContext context, {
    required bool achieved,
    required String goalId,
  }) async {
    if (achieved && context.mounted) {
      Haptics.medium();
      await openAchieved(context, goalId, celebrate: true);
    }
  }

  /// Asks for goal details and creates it. Returns the new goal, if any.
  static Future<Goal?> create(BuildContext context) async {
    final GoalDraft? draft = await showGoalForm(context);
    if (draft == null || !context.mounted) {
      return null;
    }
    return context.read<GoalsViewModel>().createGoal(
      title: draft.title,
      trackingType: draft.trackingType,
      targetAmount: draft.targetAmount,
      why: draft.why,
    );
  }
}
