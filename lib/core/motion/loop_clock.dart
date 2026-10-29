import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// A repeating 0..1 value that needs no `AnimationController`, so looping
/// effects (shimmer) can live in stateless widgets.
///
/// It only schedules frames while something is listening, and stops by
/// itself when the last listener leaves.
class LoopClock extends ChangeNotifier {
  LoopClock._(this.period);

  static final Map<int, LoopClock> _shared = <int, LoopClock>{};

  /// One clock per period, shared by every widget that uses it.
  static LoopClock shared(Duration period) =>
      _shared.putIfAbsent(period.inMicroseconds, () => LoopClock._(period));

  final Duration period;

  double _value = 0;
  Duration? _origin;
  bool _scheduled = false;

  /// Position within the current loop, 0 (inclusive) to 1 (exclusive).
  double get value => _value;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _schedule();
  }

  void _schedule() {
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_tick);
  }

  void _tick(Duration timestamp) {
    _scheduled = false;
    if (!hasListeners) {
      _origin = null;
      return;
    }
    final Duration origin = _origin ??= timestamp;
    _value =
        ((timestamp - origin).inMicroseconds % period.inMicroseconds) /
        period.inMicroseconds;
    notifyListeners();
    _schedule();
  }
}
