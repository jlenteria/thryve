import 'package:flutter/material.dart';

import '../../../core/services/image_store.dart';
import '../../../core/state/view_model.dart';
import '../../../data/models/models.dart';

/// Form state for adding or editing a Wall item, including a photo picked
/// but not yet saved.
class WallEditorViewModel extends ViewModel {
  WallEditorViewModel({this.initial})
    : title = TextEditingController(text: initial?.title ?? ''),
      note = TextEditingController(text: initial?.note ?? ''),
      nextStep = TextEditingController(text: initial?.nextStep ?? ''),
      _image = initial?.image ?? '',
      _category = initial?.category ?? categories.first {
    url = TextEditingController(
      text: ImageStore.isRemote(_image) ? _image : '',
    );
    options = <String>[
      ...categories,
      if (!categories.contains(_category)) _category,
    ];
  }

  static const List<String> categories = <String>[
    'Inspiration',
    'Family',
    'Relationships',
    'Personal Growth',
    'Career',
    'Business',
    'Financial',
    'Health & Fitness',
    'Education',
    'Travel',
    'Nature',
    'Home',
    'Workspace',
    'Lifestyle',
    'Creativity',
    'Spirituality',
    'Milestone',
    'Quote',
    'Other',
  ];

  final WallItem? initial;
  final TextEditingController title;
  final TextEditingController note;
  final TextEditingController nextStep;
  late final TextEditingController url;
  late final List<String> options;

  String _category;
  String _image;

  /// A newly picked file that hasn't been saved yet; deleted if the sheet
  /// is dismissed or another image replaces it.
  String? _unsavedPick;
  bool _saved = false;
  bool _isPicking = false;
  String? _error;

  bool get isEditing => initial != null;
  String get category => _category;
  String get image => _image;
  bool get hasImage => _image.isNotEmpty;
  bool get isPicking => _isPicking;
  String? get error => _error;

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  Future<void> pickPhoto() async {
    _isPicking = true;
    _error = null;
    notifyListeners();
    try {
      final String? ref = await ImageStore.pickFromGallery();
      if (ref == null) {
        return;
      }
      if (isDisposed) {
        // The sheet closed while the picker was open: don't leak the file.
        await ImageStore.delete(ref);
        return;
      }
      final String? previous = _unsavedPick;
      _unsavedPick = ref;
      _image = ref;
      url.clear();
      _discard(previous);
    } on Object {
      _error = 'Could not open the photo library.';
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }

  void usePastedUrl() {
    final String link = url.text.trim();
    if (!ImageStore.isRemote(link)) {
      _error = 'Paste a link that starts with http(s)://';
    } else {
      _image = link;
      _error = null;
    }
    notifyListeners();
  }

  /// The validated draft, or null (with [error] set) if the title or image
  /// is missing.
  WallDraft? submit() {
    final String pasted = url.text.trim();
    final String chosen = ImageStore.isRemote(pasted) ? pasted : _image;
    if (title.text.trim().isEmpty || chosen.isEmpty) {
      _error = 'Add a title and choose an image.';
      notifyListeners();
      return null;
    }
    if (chosen != _unsavedPick) {
      _discard(_unsavedPick);
    }
    _saved = true;
    return WallDraft(
      title: title.text.trim(),
      category: _category,
      image: chosen,
      note: note.text.trim(),
      nextStep: nextStep.text.trim(),
    );
  }

  /// Deletes a picked file that was never saved, best effort: a leftover file
  /// is harmless, a thrown error out of [dispose] is not.
  void _discard(String? ref) {
    if (ref == null) {
      return;
    }
    ImageStore.delete(ref).catchError((Object error) {
      debugPrint('Thryve: could not remove unsaved Wall image ($error).');
    });
  }

  @override
  void dispose() {
    if (!_saved) {
      _discard(_unsavedPick);
    }
    title.dispose();
    note.dispose();
    nextStep.dispose();
    url.dispose();
    super.dispose();
  }
}
