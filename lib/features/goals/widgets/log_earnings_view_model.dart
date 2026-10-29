import 'package:flutter/material.dart';

import '../../../core/state/view_model.dart';
import '../../../core/utils/formatters.dart';

/// Form state for the "Log earnings" sheet.
class LogEarningsViewModel extends ViewModel {
  final TextEditingController amount = TextEditingController();
  String? _error;

  String? get error => _error;

  /// The parsed amount, or null (with [error] set) if it is invalid.
  double? submit() {
    final double? parsed = Formatters.parseAmount(amount.text);
    _error = parsed == null ? 'Enter an amount greater than zero' : null;
    notifyListeners();
    return parsed;
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }
}
