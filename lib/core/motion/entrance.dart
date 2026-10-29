import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// Fades and slides [child] in the first time it appears. Pass a [key] that
/// identifies the item (e.g. its id) in lists so only genuinely new items
/// animate. With [grow] the item also opens its height, which makes inserts
/// push the rest of the list down smoothly.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.medium,
    this.offset = 16,
    this.grow = false,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final bool grow;

  /// Delay for the [index]th item of a staggered group.
  static Duration stagger(int index, {int stepMs = 50, int maxSteps = 6}) =>
      Duration(milliseconds: stepMs * math.min(index, maxSteps));

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return child;
    }
    final Duration total = delay + duration;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      // The delay is the leading part of one animation, so no timers needed.
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Motion.standard,
      ),
      child: child,
      builder: (BuildContext context, double t, Widget? child) {
        Widget result = Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offset),
            child: child,
          ),
        );
        if (grow) {
          result = Align(
            alignment: Alignment.topCenter,
            heightFactor: t.clamp(0, 1),
            child: result,
          );
        }
        return result;
      },
    );
  }
}

/// A one-off scale "pop" with overshoot, for icons in empty states.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return child;
    }
    final Duration total = delay + Motion.slow;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Motion.bouncy,
      ),
      child: child,
      builder: (BuildContext context, double t, Widget? child) =>
          Transform.scale(
            scale: 0.4 + 0.6 * t,
            child: Opacity(opacity: t.clamp(0, 1), child: child),
          ),
    );
  }
}

/// Briefly scales [child] up and back whenever [trigger] changes (and once
/// when it first appears).
///
/// Stateful on purpose: restarting the animation must not rebuild [child],
/// otherwise a keyed-off change would remount the subtree and reset any
/// animation inside it (a counting number would restart from zero).
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.trigger,
    required this.child,
    this.scale = 1.15,
  });

  final Object? trigger;
  final Widget child;
  final double scale;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  /// The trigger the current pulse was started for; [_unset] before the first
  /// build, which is what makes the appearance pulse.
  Object? _pulsed = _unset;

  static const Object _unset = Object();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startPulse(BuildContext context) {
    _controller
      ..duration = Motion.of(context, Motion.medium)
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return widget.child;
    }
    if (_pulsed != widget.trigger) {
      _pulsed = widget.trigger;
      _startPulse(context);
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) => Transform.scale(
        scale: 1 + (widget.scale - 1) * math.sin(math.pi * _controller.value),
        child: child,
      ),
    );
  }
}

/// Counts from the previous value to [value] whenever it changes, and from
/// zero when first shown. [builder] receives the in-between number.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.builder,
    this.duration = Motion.slow,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: Motion.of(context, duration),
      curve: Motion.standard,
      builder: (BuildContext context, double current, Widget? _) =>
          builder(context, current),
    );
  }
}
