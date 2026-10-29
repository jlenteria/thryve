import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/motion/entrance.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../onboarding_view_model.dart';
import 'onboarding_card.dart';

/// Closing onboarding page: explains the daily nudge before the OS asks for
/// notification permission, so the system prompt isn't a surprise.
class StepNotifications extends StatelessWidget {
  const StepNotifications({super.key});

  Future<void> _onFinish(
    BuildContext context, {
    required bool enableReminders,
  }) async {
    final OnboardingViewModel vm = context.read<OnboardingViewModel>();
    String? message;
    try {
      message = await vm.complete(enableReminders: enableReminders);
    } on Object {
      message = 'Something went wrong. Please try again.';
    }
    if (message != null && context.mounted) {
      context.showSnack(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Consumer<OnboardingViewModel>(
      builder: (_, OnboardingViewModel vm, _) {
        return Entrance(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 32),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: cs.primary,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Allow notifications',
                    style: text.headlineLarge?.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'So we can nudge you at ${vm.formattedTime}, every day.\n'
                    'One reminder a day, nothing else.',
                    style: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  const OnboardingCard(
                    child: Column(
                      children: <Widget>[
                        _Benefit(
                          icon: Icons.schedule,
                          label: 'Arrives right on time',
                        ),
                        SizedBox(height: 14),
                        _Benefit(
                          icon: Icons.favorite_outline,
                          label: 'Reminds you who you are doing it for',
                        ),
                        SizedBox(height: 14),
                        _Benefit(
                          icon: Icons.tune,
                          label: 'Change or turn it off anytime in Settings',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Allow & Start Thriving',
                    icon: Icons.arrow_forward,
                    isLoading: vm.isLoading,
                    onPressed: () => _onFinish(context, enableReminders: true),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () => _onFinish(context, enableReminders: false),
                    child: Text(
                      'Not now',
                      style: text.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, color: cs.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}
