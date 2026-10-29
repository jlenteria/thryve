import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/motion/entrance.dart';
import '../../../core/motion/motion.dart';
import '../../../core/services/reminder_copy.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../onboarding_view_model.dart';
import 'am_pm_button.dart';
import 'drum_picker.dart';
import 'onboarding_card.dart';

class StepThree extends StatelessWidget {
  const StepThree({super.key});

  Future<void> _onStart(
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

    return Consumer<OnboardingViewModel>(
      builder: (_, OnboardingViewModel vm, _) {
        final ReminderCopy copy = vm.reminderCopy;
        final String prefix = copy.prefix;
        final String highlight = copy.highlight;

        return Entrance(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: <Widget>[
                  // Step + 100%
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'STEP 3 OF 3',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '100%',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 2 / 3, end: 1),
                    duration: Motion.of(context, Motion.slow),
                    curve: Motion.standard,
                    builder: (BuildContext context, double value, Widget? _) =>
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: cs.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.primary,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'When will you grow?',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Consistency is the soil where\ncharacter takes root.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Time picker card
                  OnboardingCard(
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            DrumPicker(
                              controller: vm.hourWheel,
                              semanticLabel: 'Hour',
                              value: vm.reminderHour,
                              min: 1,
                              max: 12,
                              onChanged: (int h) {
                                Haptics.selection();
                                vm.setReminderHour(h);
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            DrumPicker(
                              controller: vm.minuteWheel,
                              semanticLabel: 'Minute',
                              value: vm.reminderMinute,
                              min: 0,
                              max: 59,
                              onChanged: (int m) {
                                Haptics.selection();
                                vm.setReminderMinute(m);
                              },
                              pad: true,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              children: <Widget>[
                                AmPmButton(
                                  label: 'AM',
                                  selected: vm.isAm,
                                  onTap: () {
                                    Haptics.selection();
                                    vm.setAmPm(isAm: true);
                                  },
                                ),
                                const SizedBox(height: 6),
                                AmPmButton(
                                  label: 'PM',
                                  selected: !vm.isAm,
                                  onTap: () {
                                    Haptics.selection();
                                    vm.setAmPm(isAm: false);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We'll nudge you here, every single day",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notification preview
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: cs.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'DAILY THRYVE REMINDER',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    vm.formattedTime,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Notification title
                              Text(
                                vm.reminderCopy.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                              ),
                              const SizedBox(height: 3),

                              // Notification body with highlighted anchor in green
                              RichText(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                  children: <InlineSpan>[
                                    TextSpan(text: prefix),
                                    TextSpan(
                                      text: highlight,
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Preview of your daily motivation',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward,
                    onPressed: vm.isLoading ? null : vm.nextStep,
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () => _onStart(context, enableReminders: false),
                    child: Text(
                      "I'll set this later",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer quote
                  Column(
                    children: <Widget>[
                      Container(
                        width: 1,
                        height: 48,
                        color: cs.primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"The best time to plant a tree was 20 years ago. The second best time is now."',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
