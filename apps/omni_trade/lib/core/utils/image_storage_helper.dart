import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from [source] (camera or gallery) and persists it locally.
  /// Returns the saved absolute file path or null if cancelled.
  static Future<String?> pickAndSaveImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(appDir.path, 'trades_media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final ext = p.extension(pickedFile.path).isNotEmpty ? p.extension(pickedFile.path) : '.jpg';
      final fileName = 'trade_chart_${const Uuid().v4()}$ext';
      final targetPath = p.join(mediaDir.path, fileName);

      final savedFile = await File(pickedFile.path).copy(targetPath);
      return savedFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a previously stored image file if it exists.
  static Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
