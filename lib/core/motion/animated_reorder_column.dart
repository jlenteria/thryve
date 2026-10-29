import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'motion.dart';

/// A column whose items slide to their new positions when the same set of
/// ids arrives in a different order (e.g. pinning moves a card to the top).
///
/// Adding or removing ids is not animated here; wrap items in `Entrance`
/// for that. Stateful on purpose: it must remember where each item was
/// before the reorder.
class AnimatedReorderColumn extends StatefulWidget {
  const AnimatedReorderColumn({
    super.key,
    required this.ids,
    required this.itemBuilder,
  });

  /// Unique, stable id of each item, in display order.
  final List<String> ids;

  final Widget Function(BuildContext context, String id) itemBuilder;

  @override
  State<AnimatedReorderColumn> createState() => _AnimatedReorderColumnState();
}

class _AnimatedReorderColumnState extends State<AnimatedReorderColumn>
    with SingleTickerProviderStateMixin {
  /// Lets us read each item's on-screen position and size.
  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  /// How far each item must travel back to where it was drawn before the
  /// reorder (positive = it started lower on screen).
  Map<String, double> _starts = <String, double>{};

  /// Created in [initState] rather than lazily: a lazily initialized
  /// [AnimationController] can first be touched by [dispose], which asks the
  /// vsync ancestor after the element already deactivated.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  GlobalKey _keyFor(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'reorder-$id'));

  @override
  void didUpdateWidget(AnimatedReorderColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _keys.removeWhere((String id, _) => !widget.ids.contains(id));

    final bool pureReorder =
        !listEquals(oldWidget.ids, widget.ids) &&
        oldWidget.ids.length == widget.ids.length &&
        oldWidget.ids.toSet().containsAll(widget.ids);
    if (!pureReorder || Motion.reduced(context)) {
      return;
    }
    final Map<String, double>? starts = _measureStarts(oldWidget.ids);
    if (starts == null) {
      return;
    }
    _starts = starts;
    _controller
      ..duration = Motion.slow
      ..forward(from: 0);
  }

  /// Compares where each item is drawn right now (including any animation
  /// still in flight) with where the new order will put it. Returns null if
  /// anything can't be measured, in which case the list just snaps.
  Map<String, double>? _measureStarts(List<String> oldIds) {
    final RenderObject? columnObject = context.findRenderObject();
    if (columnObject is! RenderBox || !columnObject.hasSize) {
      return null;
    }
    final double columnTop = columnObject.localToGlobal(Offset.zero).dy;

    final Map<String, double> drawnTop = <String, double>{};
    final Map<String, double> height = <String, double>{};
    for (final String id in oldIds) {
      final RenderObject? object = _keys[id]?.currentContext
          ?.findRenderObject();
      if (object is! RenderBox || !object.hasSize) {
        return null;
      }
      drawnTop[id] = object.localToGlobal(Offset.zero).dy;
      height[id] = object.size.height;
    }

    final Map<String, double> starts = <String, double>{};
    double cursor = columnTop;
    for (final String id in widget.ids) {
      starts[id] = drawnTop[id]! - cursor;
      cursor += height[id]!;
    }
    return starts;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final String id in widget.ids)
          AnimatedBuilder(
            key: ValueKey<String>(id),
            animation: _controller,
            // The item itself is built once; only the offset changes per frame.
            child: KeyedSubtree(
              key: _keyFor(id),
              child: widget.itemBuilder(context, id),
            ),
            builder: (BuildContext context, Widget? child) {
              final double start = _starts[id] ?? 0;
              final double remaining =
                  1 - Motion.standard.transform(_controller.value);
              return Transform.translate(
                offset: Offset(0, start * remaining),
                child: child,
              );
            },
          ),
      ],
    );
  }
}
