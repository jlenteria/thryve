import 'package:flutter/material.dart';

import '../../../core/state/view_model.dart';
import '../../../data/models/models.dart';

/// Form state for adding or editing a milestone.
class MilestoneViewModel extends ViewModel {
  MilestoneViewModel({this.initial})
    : title = TextEditingController(text: initial?.title ?? ''),
      note = TextEditingController(text: initial?.note ?? ''),
      value = TextEditingController(text: initial?.valueLabel ?? ''),
      _status = initial?.status ?? MilestoneStatus.pending;

  final Milestone? initial;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController title;
  final TextEditingController note;
  final TextEditingController value;
  MilestoneStatus _status;

  bool get isEditing => initial != null;
  MilestoneStatus get status => _status;

  void setStatus(MilestoneStatus next) {
    _status = next;
    notifyListeners();
  }

  /// The validated draft, or null if the form has errors.
  MilestoneDraft? submit() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return null;
    }
    String? optional(String text) {
      final String trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return MilestoneDraft(
      title: title.text.trim(),
      status: _status,
      note: optional(note.text),
      valueLabel: optional(value.text),
    );
  }

  @override
  void dispose() {
    title.dispose();
    note.dispose();
    value.dispose();
    super.dispose();
  }
}
