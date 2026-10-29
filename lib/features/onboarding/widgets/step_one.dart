import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/motion/entrance.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/fields/custom_text_form_field.dart';
import '../../../core/widgets/sheets.dart';
import '../onboarding_view_model.dart';
import 'onboarding_card.dart';
import 'step_header.dart';

class StepOne extends StatelessWidget {
  const StepOne({super.key});

  Future<void> _explainWhy(BuildContext context) => showThryveSheet<void>(
    context,
    (BuildContext context) => ThryveBottomSheet(
      title: 'Why we ask',
      content: const Text(
        'Your name personalises your reminders. Your big dream becomes your '
        'first goal, so Thryve can show your progress from day one.\n\n'
        'Everything stays on this device.',
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Consumer<OnboardingViewModel>(
      builder: (_, OnboardingViewModel vm, _) {
        return Entrance(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const StepHeader(step: 1, total: 3),
                  const SizedBox(height: 12),
                  // Wordmark
                  Center(
                    child: Text(
                      'Thryve',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hero Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          height: 160,
                          color: cs.primaryContainer,
                          child: Image.asset(
                            'assets/images/step_1_banner.jpg',
                            cacheWidth: 1000,
                            excludeFromSemantics: true,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: cs.surfaceContainer,
                              child: Icon(
                                Icons.landscape_outlined,
                                size: 48,
                                color: cs.outline,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              'THE JOURNEY BEGINS',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: cs.primary,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Glass card
                  OnboardingCard(
                    radius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "What's your name?",
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(color: cs.primary),
                        ),
                        const SizedBox(height: 10),
                        CustomTextFormField(
                          controller: vm.nameController,
                          onChanged: vm.onNameChanged,
                          hint: 'e.g. Juan Dela Cruz',
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.person_outline,
                              color: cs.outline,
                              size: 22,
                            ),
                          ),
                          errorText: vm.showNameError
                              ? 'Please enter your name'
                              : null,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'And your big dream?',
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(color: cs.primary),
                        ),
                        const SizedBox(height: 10),
                        CustomTextFormField(
                          controller: vm.dreamController,
                          onChanged: vm.onDreamChanged,
                          hint: 'Write down your main goal...',
                          prefix: Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 8,
                              bottom: 42,
                            ),
                            child: Icon(
                              Icons.auto_awesome_outlined,
                              color: cs.outline,
                              size: 22,
                            ),
                          ),
                          minLines: 3,
                          maxLines: 3,
                          errorText: vm.showDreamError
                              ? 'Please write your dream'
                              : null,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),

                        // Quote banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cs.secondaryContainer.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.park_outlined,
                                  size: 18,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '"The best time to plant a tree was 20 years ago. The second best time is now."',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Continue',
                          icon: Icons.arrow_forward,
                          onPressed: vm.continueFromStep1,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _explainWhy(context),
                            icon: Icon(
                              Icons.help_outline,
                              size: 14,
                              color: cs.outline,
                            ),
                            label: Text(
                              'WHY ARE WE ASKING THIS?',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: cs.outline),
                            ),
                          ),
                        ),
                      ],
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
