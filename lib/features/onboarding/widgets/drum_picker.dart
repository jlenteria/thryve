import 'package:flutter/material.dart';

/// A looping number wheel. Stateless: the owner supplies and disposes the
/// [controller] (see `OnboardingViewModel`).
class DrumPicker extends StatelessWidget {
  const DrumPicker({
    super.key,
    required this.controller,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.pad = false,
    this.semanticLabel,
  });

  static const double _itemExtent = 46;
  static const Duration _animDuration = Duration(milliseconds: 250);

  final FixedExtentScrollController controller;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool pad;

  /// Spoken name for the wheel, e.g. "Hour".
  final String? semanticLabel;

  /// The controller to start a wheel showing [value].
  static FixedExtentScrollController createController({
    required int value,
    required int min,
  }) => FixedExtentScrollController(initialItem: value - min);

  /// Animates [controller] to [value] by the shortest path around the loop.
  /// A no-op if the wheel is not attached or already there.
  static void syncTo(
    FixedExtentScrollController controller, {
    required int value,
    required int min,
    required int max,
  }) {
    if (!controller.hasClients) {
      return;
    }
    final int count = max - min + 1;
    final int current = ((controller.selectedItem % count) + count) % count;
    final int target = value - min;
    if (current == target) {
      return;
    }
    int delta = target - current;
    if (delta > count ~/ 2) {
      delta -= count;
    } else if (delta < -(count ~/ 2)) {
      delta += count;
    }
    controller.animateToItem(
      controller.selectedItem + delta,
      duration: _animDuration,
      curve: Curves.easeOut,
    );
  }

  int get _count => max - min + 1;

  /// Wraps a raw (possibly negative or overflowing) wheel index into range.
  int _normalize(int rawIndex) => ((rawIndex % _count) + _count) % _count;

  String _fmt(int v) => pad ? v.toString().padLeft(2, '0') : v.toString();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: semanticLabel,
      value: _fmt(value),
      increasedValue: _fmt(min + _normalize(value - min + 1)),
      decreasedValue: _fmt(min + _normalize(value - min - 1)),
      onIncrease: () => onChanged(min + _normalize(value - min + 1)),
      onDecrease: () => onChanged(min + _normalize(value - min - 1)),
      child: ExcludeSemantics(
        child: SizedBox(
          width: 64,
          height: _itemExtent * 3,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _itemExtent,
            diameterRatio: 1.4,
            perspective: 0.004,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (int index) =>
                onChanged(min + _normalize(index)),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (BuildContext context, int index) {
                final int slot = _normalize(index);
                final bool isSelected = slot == value - min;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.animateToItem(
                    index,
                    duration: _animDuration,
                    curve: Curves.easeOut,
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: _animDuration,
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontSize: isSelected ? 40 : 28,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.45),
                      ),
                      child: Text(_fmt(min + slot)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
