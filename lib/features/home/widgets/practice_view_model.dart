import 'package:flutter/material.dart';

import '../../../core/state/view_model.dart';

/// Form state for adding or editing a daily practice.
class PracticeViewModel extends ViewModel {
  PracticeViewModel({this.initial = ''})
    : title = TextEditingController(text: initial);

  final String initial;
  final TextEditingController title;

  bool get isEditing => initial.isNotEmpty;

  /// The trimmed title, or null if it is blank.
  String? submit() {
    final String clean = title.text.trim();
    return clean.isEmpty ? null : clean;
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }
}
