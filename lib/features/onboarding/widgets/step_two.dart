import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/motion/entrance.dart';
import '../../../core/services/image_store.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/fields/custom_text_form_field.dart';
import '../onboarding_view_model.dart';
import 'onboarding_card.dart';
import 'step_header.dart';

class StepTwo extends StatelessWidget {
  const StepTwo({super.key});

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
                children: <Widget>[
                  const StepHeader(step: 2, total: 3),
                  const SizedBox(height: 32),
                  Text(
                    'Who are you doing\nthis for?',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(color: cs.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This becomes your anchor - the reason\nyou keep going.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Card
                  OnboardingCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Photo Picker
                        Semantics(
                          button: true,
                          label: vm.anchorImage == null
                              ? 'Add an anchor image, optional'
                              : 'Change anchor image',
                          child: GestureDetector(
                            onTap: () async {
                              final bool ok = await vm.pickAnchorImage();
                              if (!ok && context.mounted) {
                                context.showSnack(
                                  'Could not open the photo library.',
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: vm.anchorImage != null
                                      ? cs.primary
                                      : cs.outlineVariant,
                                  width: vm.anchorImage != null ? 2 : 1,
                                ),
                                image: vm.anchorImage != null
                                    ? DecorationImage(
                                        image: ImageStore.provider(
                                          vm.anchorImage,
                                        )!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: vm.anchorImage == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: cs.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add_a_photo_outlined,
                                            color: cs.primary,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Add an Anchor Image (Optional)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 16,
                                              color: cs.onPrimary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Anchor Set',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: cs.onPrimary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (vm.anchorImage != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: vm.removeAnchorImage,
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Remove image'),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Write your anchor',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: vm.anchorController,
                          onChanged: vm.onAnchorChanged,
                          minLines: 4,
                          maxLines: 4,
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                          hint: "e.g. For my daughter's future...",
                          errorText: vm.showAnchorError
                              ? 'Please write your anchor'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rooting pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.eco, size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'ROOTING YOUR PURPOSE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: cs.primary,
                                letterSpacing: 0.08,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward,
                    onPressed: vm.continueFromStep2,
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => vm.nextStep(),
                    child: Text(
                      'Skip for now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                        decorationColor: cs.primary.withValues(alpha: 0.5),
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
