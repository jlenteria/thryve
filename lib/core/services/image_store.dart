import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Stores user-picked images as files in the app documents directory.
///
/// References are saved as `local:<file name>` rather than absolute paths,
/// because iOS changes the app container path between installs and updates.
/// Earlier builds stored base64 `data:` URIs; those still resolve.
abstract final class ImageStore {
  static const String _scheme = 'local:';
  static const String _memoryScheme = 'mem:';
  static const Uuid _uuid = Uuid();
  static String? _directory;

  /// Bytes for images picked where there is no filesystem (web, or a failed
  /// [initialize]). Session-only by design: the alternative, inlining base64
  /// into the single SharedPreferences string that holds the whole AppState,
  /// eventually breaks the storage quota and every later save fails.
  static final Map<String, Uint8List> _memory = <String, Uint8List>{};

  /// [MemoryImage] compares by byte-list *identity*, so decoding a `data:` URI
  /// on each build produces a new cache key every time: repeated buffer
  /// creation, decode churn and re-fading in lists.
  static final Map<String, ImageProvider<Object>> _providers =
      <String, ImageProvider<Object>>{};

  static Future<void> initialize() async {
    if (kIsWeb || _directory != null) {
      return;
    }
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory images = Directory('${docs.path}/images');
      if (!images.existsSync()) {
        await images.create(recursive: true);
      }
      _directory = images.path;
    } on Object catch (error) {
      debugPrint('Thryve: image storage unavailable ($error).');
    }
  }

  /// Opens the gallery and returns a reference to the stored copy, or null
  /// if the user cancelled.
  static Future<String?> pickFromGallery({double maxDimension = 1600}) async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: 82,
    );
    if (picked == null) {
      return null;
    }
    final Uint8List bytes = await picked.readAsBytes();
    final String? directory = _directory;
    if (directory == null) {
      // No filesystem: keep the bytes in memory and store only a handle.
      final String name = _uuid.v4();
      _memory[name] = bytes;
      _providers['$_memoryScheme$name'] = MemoryImage(bytes);
      return '$_memoryScheme$name';
    }
    final String name = '${_uuid.v4()}.jpg';
    await File('$directory/$name').writeAsBytes(bytes, flush: true);
    return '$_scheme$name';
  }

  /// Deletes a stored image. Remote URLs and data URIs are ignored.
  static Future<void> delete(String? ref) async {
    if (ref != null && ref.startsWith(_memoryScheme)) {
      _memory.remove(ref.substring(_memoryScheme.length));
      _providers.remove(ref);
      return;
    }
    final File? file = _fileFor(ref);
    if (file != null && file.existsSync()) {
      await file.delete();
    }
  }

  static bool isRemote(String ref) =>
      ref.startsWith('http://') || ref.startsWith('https://');

  static ImageProvider<Object>? provider(String? ref) {
    if (ref == null || ref.isEmpty) {
      return null;
    }
    final ImageProvider<Object>? cached = _providers[ref];
    if (cached != null) {
      return cached;
    }
    if (ref.startsWith('data:image/')) {
      try {
        final MemoryImage image = MemoryImage(
          base64Decode(ref.substring(ref.indexOf(',') + 1)),
        );
        // Legacy inline images are decoded once per reference, not per build.
        _providers[ref] = image;
        return image;
      } on FormatException {
        return null;
      }
    }
    if (ref.startsWith(_scheme)) {
      final File? file = _fileFor(ref);
      return file == null ? null : FileImage(file);
    }
    if (ref.startsWith(_memoryScheme)) {
      // Its bytes lived in this process only; after a restart the reference is
      // dangling, so fall back to the placeholder rather than a bad URL.
      return null;
    }
    return NetworkImage(ref);
  }

  static File? _fileFor(String? ref) {
    final String? directory = _directory;
    if (ref == null || !ref.startsWith(_scheme) || directory == null) {
      return null;
    }
    final String name = ref.substring(_scheme.length);
    // A reference is read back from saved data, so it must stay a bare file
    // name: `local:../../x` would reach outside the images folder for both
    // rendering and deletion.
    if (name.isEmpty ||
        name != name.trim() ||
        name.contains('/') ||
        name.contains(r'\') ||
        name.contains('..')) {
      return null;
    }
    return File('$directory/$name');
  }
}
