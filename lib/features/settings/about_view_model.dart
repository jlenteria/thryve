import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';

import '../../core/state/view_model.dart';

/// Package information shown on the About page.
class AboutViewModel extends ViewModel {
  AboutViewModel() {
    unawaited(_loadVersion());
  }

  String _version = 'Loading…';
  String get version => _version;

  Future<void> _loadVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _version = info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';
    } on Object {
      _version = 'Unavailable';
    }
    notifyListeners();
  }
}
