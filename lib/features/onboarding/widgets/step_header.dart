import 'package:flutter/material.dart';
import '../../../core/motion/motion.dart';

class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'STEP $step OF $total',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.primary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        // Slides from the previous step's fill to this one's.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: (step - 1) / total, end: step / total),
          duration: Motion.of(context, Motion.slow),
          curve: Motion.standard,
          builder: (BuildContext context, double value, Widget? _) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ),
      ],
    );
  }
}
