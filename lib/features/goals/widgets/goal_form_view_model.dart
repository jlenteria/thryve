import 'package:flutter/material.dart';

import '../../../core/state/view_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

/// Form state for creating or editing a goal.
class GoalFormViewModel extends ViewModel {
  GoalFormViewModel({this.initial})
    : title = TextEditingController(text: initial?.title ?? ''),
      target = TextEditingController(
        text: initial != null && initial.targetAmount > 0
            ? Formatters.amount(initial.targetAmount)
            : '',
      ),
      why = TextEditingController(text: initial?.why ?? ''),
      _type = initial?.trackingType ?? GoalTrackingType.progress;

  final Goal? initial;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController title;
  final TextEditingController target;
  final TextEditingController why;
  GoalTrackingType _type;

  bool get isEditing => initial != null;
  GoalTrackingType get type => _type;
  bool get isMoney => _type == GoalTrackingType.money;

  void setType(GoalTrackingType value) {
    _type = value;
    notifyListeners();
  }

  /// The validated draft, or null if the form has errors.
  GoalDraft? submit() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return null;
    }
    return GoalDraft(
      title: title.text.trim(),
      trackingType: _type,
      targetAmount: isMoney ? Formatters.parseAmount(target.text) ?? 0 : 0,
      why: why.text.trim(),
    );
  }

  @override
  void dispose() {
    title.dispose();
    target.dispose();
    why.dispose();
    super.dispose();
  }
}
