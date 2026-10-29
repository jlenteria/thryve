import 'package:flutter/material.dart';

/// Shows [message] with an Undo action. [onExpired] runs when the snack bar
/// goes away without Undo being tapped (timeout, dismissed, or replaced by
/// another snack bar), which is the moment to finish clean-up work such as
/// deleting an image file.
///
/// Takes a [ScaffoldMessengerState] rather than a context so callers can
/// grab it before popping the screen they are on.
void showUndoSnack(
  ScaffoldMessengerState messenger, {
  required String message,
  required VoidCallback onUndo,
  VoidCallback? onExpired,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Undo', onPressed: onUndo),
        persist: false,
      ),
    ).closed.then((SnackBarClosedReason reason) {
      if (reason != SnackBarClosedReason.action) {
        onExpired?.call();
      }
    });
}
