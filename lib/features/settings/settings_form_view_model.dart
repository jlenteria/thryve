import 'package:flutter/material.dart';

import '../../core/state/view_model.dart';
import '../../data/models/models.dart';

/// Profile form state for the Settings screen, seeded from the saved profile.
class SettingsFormViewModel extends ViewModel {
  SettingsFormViewModel(UserProfile user)
    : name = TextEditingController(text: user.name),
      dream = TextEditingController(text: user.bigDream ?? ''),
      anchor = TextEditingController(text: user.anchor ?? '');

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController name;
  final TextEditingController dream;
  final TextEditingController anchor;

  bool validate() => formKey.currentState?.validate() ?? false;

  @override
  void dispose() {
    name.dispose();
    dream.dispose();
    anchor.dispose();
    super.dispose();
  }
}
