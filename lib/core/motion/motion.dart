import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared timing and easing, so every animation in the app feels related.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration celebration = Duration(milliseconds: 2800);

  /// Things arriving or settling.
  static const Curve standard = Curves.easeOutCubic;

  /// Playful overshoot for rewards.
  static const Curve bouncy = Curves.elasticOut;

  /// Whether the user asked the system to minimise motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when motion is reduced. Animations with a zero
  /// duration jump straight to their end state.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Thin wrapper over the platform haptics, in one place so they are easy to
/// find and tune. Feedback is a nicety, so failures (no vibration hardware,
/// desktop, tests) are ignored.
abstract final class Haptics {
  /// Light tap: toggling a practice, pinning.
  static void light() => _fire(HapticFeedback.lightImpact);

  /// Reward: finishing a goal.
  static void medium() => _fire(HapticFeedback.mediumImpact);

  /// Picker ticks and small selections.
  static void selection() => _fire(HapticFeedback.selectionClick);

  static void _fire(Future<void> Function() feedback) {
    try {
      unawaited(feedback().catchError((Object _) {}));
    } on Object {
      // Ignored on purpose.
    }
  }
}
