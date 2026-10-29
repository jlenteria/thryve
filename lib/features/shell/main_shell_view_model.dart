import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/state/view_model.dart';

enum ShellTab { home, goals, wall, review, settings }

class MainShellViewModel extends ViewModel {
  ShellTab _tab = ShellTab.home;

  ShellTab get tab => _tab;

  void select(ShellTab tab) {
    if (tab == _tab) {
      return;
    }
    _tab = tab;
    notifyListeners();
  }
}

extension ShellNavigation on BuildContext {
  /// Switches the bottom-nav tab from anywhere inside [MainShell].
  void goToTab(ShellTab tab) => read<MainShellViewModel>().select(tab);
}
