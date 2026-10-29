import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/models.dart';

/// Loads and saves [AppState] as a single JSON document in
/// SharedPreferences. Writes are serialized so a slow write can never land
/// after (and overwrite) a newer one.
class AppStateRepository {
  Future<void> _pendingWrite = Future<void>.value();

  Future<AppState> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(AppConstants.stateKey);
    if (encoded == null) {
      return const AppState();
    }
    try {
      return AppState.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
    } on Object catch (error) {
      // Never crash on corrupt local data; start fresh but keep the raw
      // payload so it can be recovered manually if needed.
      debugPrint('Thryve: could not read saved state ($error).');
      await prefs.setString(AppConstants.corruptStateKey, encoded);
      return const AppState();
    }
  }

  /// Queues a write. The returned future completes with the outcome of this
  /// write only; a failure never blocks later writes.
  Future<void> save(AppState state) async {
    // Encode synchronously so the snapshot matches the state at call time.
    final String encoded = jsonEncode(state.toJson());
    final Future<void> write = _pendingWrite.then((_) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.stateKey, encoded);
    });
    // The queue itself must always resolve so one failure can't poison it.
    _pendingWrite = write.then((_) {}, onError: (Object _) {});
    await write;
  }

  /// Completes once every queued write has settled.
  Future<void> flush() => _pendingWrite;

  /// Removes everything this repository owns, including the corrupt-data
  /// backup, so a reset really erases the user's data.
  Future<void> clear() async {
    await _pendingWrite;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.stateKey);
    await prefs.remove(AppConstants.corruptStateKey);
  }
}
