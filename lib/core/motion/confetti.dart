import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// One burst of confetti that falls once and then removes itself.
/// Place it in a `Stack` above the content; it ignores touches.
class ConfettiBurst extends StatelessWidget {
  const ConfettiBurst({super.key, required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Motion.celebration,
          builder: (BuildContext context, double t, Widget? _) => t >= 1
              ? const SizedBox.shrink()
              : SizedBox.expand(
                  child: CustomPaint(painter: _ConfettiPainter(t, colors)),
                ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final int color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.t, this.colors);

  final double t;
  final List<Color> colors;

  // Fixed seed: the same pleasing burst every time, computed once.
  static final List<_Particle> _particles = () {
    final math.Random random = math.Random(7);
    return List<_Particle>.generate(
      80,
      (int i) => _Particle(
        // Fan upward, from just left of straight-left to just right of right.
        angle: -math.pi * (0.08 + 0.84 * random.nextDouble()),
        speed: 0.35 + 0.65 * random.nextDouble(),
        spin: (random.nextDouble() - 0.5) * 14,
        size: 6 + 7 * random.nextDouble(),
        color: random.nextInt(1 << 16),
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height * 0.3);
    // Ease-out for the launch, then gravity pulls everything down.
    final double launch = Curves.easeOutCubic.transform(math.min(t * 1.6, 1));
    final double fade = t < 0.7 ? 1 : (1 - (t - 0.7) / 0.3).clamp(0, 1);
    final Paint paint = Paint();
    for (final _Particle p in _particles) {
      final double dx = math.cos(p.angle) * p.speed * size.width * 0.7 * launch;
      final double dy =
          math.sin(p.angle) * p.speed * size.height * 0.35 * launch +
          size.height * 0.9 * t * t;
      paint.color = colors[p.color % colors.length].withValues(alpha: fade);
      canvas
        ..save()
        ..translate(origin.dx + dx, origin.dy + dy)
        ..rotate(p.spin * t)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
