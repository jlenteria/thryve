import '../../core/state/store_view_model.dart';
import '../../core/utils/ids.dart';
import '../../data/models/models.dart';

/// The vision Wall: images that keep the user focused on their why.
class WallViewModel extends StoreViewModel {
  WallViewModel(super.store);

  @override
  List<Object?> watches(AppState state) => <Object?>[state.wallItems];

  // ── Read model ───────────────────────────────────────────────────

  List<WallItem> get items =>
      List<WallItem>.unmodifiable(store.state.wallItems);

  /// Pinned items first, otherwise newest first.
  List<WallItem> get sortedItems => store.state.wallItems.pinnedFirst;

  bool get hasPinned => store.state.wallItems.any((WallItem i) => i.isPinned);

  WallItem? itemById(String id) {
    for (final WallItem item in store.state.wallItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  // ── Actions ──────────────────────────────────────────────────────

  void addItem({
    required String title,
    required String category,
    required String image,
    String note = '',
    String nextStep = '',
  }) {
    final WallItem item = WallItem(
      id: Ids.next(),
      title: title.trim(),
      category: category.trim(),
      image: image.trim(),
      note: note.trim(),
      nextStep: nextStep.trim(),
    );
    store.commit(
      store.state.copyWith(
        wallItems: <WallItem>[item, ...store.state.wallItems],
      ),
    );
  }

  void updateItem(
    String id, {
    required String title,
    required String category,
    required String image,
    required String note,
    required String nextStep,
  }) {
    String? replacedImage;
    final List<WallItem> items = store.state.wallItems.map((WallItem item) {
      if (item.id != id) {
        return item;
      }
      if (item.image != image) {
        replacedImage = item.image;
      }
      return item.copyWith(
        title: title.trim(),
        category: category.trim(),
        image: image.trim(),
        note: note.trim(),
        nextStep: nextStep.trim(),
      );
    }).toList();
    store.commit(store.state.copyWith(wallItems: items));
    store.deleteImageIfUnreferenced(replacedImage);
  }

  /// Only one item can be pinned; pinning another moves the pin.
  void togglePinned(String id) {
    final bool pin = !store.state.wallItems.any(
      (WallItem item) => item.id == id && item.isPinned,
    );
    store.commit(
      store.state.copyWith(
        wallItems: store.state.wallItems
            .map(
              (WallItem item) => item.copyWith(isPinned: pin && item.id == id),
            )
            .toList(),
      ),
    );
  }

  /// Removes an item and returns it with its position, or null if it does
  /// not exist. Pass [keepImage] to offer Undo: the image file then stays
  /// until [discardImage] is called.
  ({WallItem item, int index})? removeItem(
    String id, {
    bool keepImage = false,
  }) {
    final int index = store.state.wallItems.indexWhere(
      (WallItem item) => item.id == id,
    );
    if (index < 0) {
      return null;
    }
    final WallItem item = store.state.wallItems[index];
    store.commit(
      store.state.copyWith(
        wallItems: store.state.wallItems
            .where((WallItem other) => other.id != id)
            .toList(),
      ),
    );
    if (!keepImage) {
      store.deleteImageIfUnreferenced(item.image);
    }
    return (item: item, index: index);
  }

  /// Puts back an item removed by [removeItem].
  void restoreItem(WallItem item, int index) {
    final List<WallItem> items = List<WallItem>.of(store.state.wallItems)
      ..insert(index.clamp(0, store.state.wallItems.length), item);
    store.commit(store.state.copyWith(wallItems: items));
  }

  /// Finishes a removal that was kept undoable.
  void discardImage(String? ref) => store.deleteImageIfUnreferenced(ref);
}
