import 'package:flutter/material.dart';

import 'loop_clock.dart';
import 'motion.dart';

/// Sweeps a soft highlight across [child]. Use it on placeholder shapes
/// while content loads.
class Shimmer extends StatelessWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return child;
    }
    return _ShimmerAnimation(child: child);
  }
}

class _ShimmerAnimation extends StatefulWidget {
  const _ShimmerAnimation({required this.child});

  final Widget child;

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation> {
  static const Duration _period = Duration(milliseconds: 1400);

  LoopClock? _clock;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final LoopClock clock = LoopClock.shared(_period);
    if (TickerMode.valuesOf(context).enabled) {
      if (_clock != clock) {
        _unsubscribe();
        clock.addListener(_onTick);
        _clock = clock;
      }
    } else {
      // Hidden tabs stay mounted, so an animation that keeps listening here
      // would run frames and rebuild every other shimmer for ever.
      _unsubscribe();
    }
  }

  void _unsubscribe() {
    _clock?.removeListener(_onTick);
    _clock = null;
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double t = _clock?.value ?? 0;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (Rect bounds) => LinearGradient(
        begin: Alignment(t * 4 - 2, 0),
        end: Alignment(t * 4 - 1, 0),
        colors: <Color>[
          colors.surfaceContainer,
          colors.surfaceContainerHighest,
          colors.surfaceContainer,
        ],
      ).createShader(bounds),
      child: widget.child,
    );
  }
}

/// A rounded grey block that shimmers; the building piece of skeletons.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 12});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Placeholder for the Home screen while saved data loads.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Semantics(
            label: 'Loading',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonBox(width: 220, height: 34),
                SizedBox(height: 10),
                SkeletonBox(width: 160, height: 16),
                SizedBox(height: 28),
                SkeletonBox(height: 150, radius: 16),
                SizedBox(height: 16),
                SkeletonBox(height: 190, radius: 16),
                SizedBox(height: 16),
                SkeletonBox(height: 120, radius: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
