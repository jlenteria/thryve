import '../../data/models/models.dart';
import 'app_store.dart';
import 'view_model.dart';

/// Base class for a feature's view model.
///
/// A feature declares which slices of [AppState] it cares about in [watches];
/// it only notifies its listeners when one of those slices was replaced.
/// That keeps, say, a Wall edit from rebuilding the Goals screens.
abstract class StoreViewModel extends ViewModel {
  StoreViewModel(this.store) {
    _seen = watches(store.state);
    store.addListener(_onStoreChanged);
  }

  final AppStore store;

  late List<Object?> _seen;

  /// The [AppState] slices this view model reads. Compared by identity, so
  /// return the slices themselves rather than copies.
  List<Object?> watches(AppState state);

  /// The app clock, so UI and tests agree on "now".
  DateTime now() => store.clock();

  void _onStoreChanged() {
    final List<Object?> next = watches(store.state);
    bool changed = next.length != _seen.length;
    for (int i = 0; !changed && i < next.length; i++) {
      changed = !identical(next[i], _seen[i]);
    }
    _seen = next;
    if (changed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
