import 'package:flutter/foundation.dart';

/// Base class for screen-scoped view models.
///
/// Provides a loading flag and ignores [notifyListeners] after disposal, so
/// async work that completes after the screen closes can't throw.
class ViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;

  /// True once the screen is gone; async work should stop touching state.
  bool get isDisposed => _isDisposed;

  @protected
  void startLoading() {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    notifyListeners();
  }

  @protected
  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
