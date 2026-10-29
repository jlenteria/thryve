import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get text => Theme.of(this).textTheme;

  /// Queues [message] rather than replacing whatever is showing: hiding the
  /// current bar would destroy a pending Undo snack, whose close handler
  /// finalizes the deletion (e.g. deletes the image file) with no way back.
  void showSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
