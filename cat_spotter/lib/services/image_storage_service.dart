import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';

class ImageStorageService {
  /// Saves [tempFile] to the app documents directory.
  /// Returns the **relative** path (e.g. 'cat_photos/uuid.jpg') for DB storage.
  static Future<String> saveImage(XFile tempFile,
      {bool isCover = false}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final subDir =
        isCover ? AppConstants.coverPhotosDir : AppConstants.catPhotosDir;
    final dir = Directory('${appDir.path}/$subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final fileName = '${const Uuid().v4()}.jpg';
    final relativePath = '$subDir/$fileName';
    await tempFile.saveTo('${appDir.path}/$relativePath');
    return relativePath;
  }

  /// Deletes the file at [relativePath]. Safe to call with null or empty string.
  static Future<void> deleteImage(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return;
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/$relativePath');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Resolves a relative path to an absolute File.
  static Future<File> resolveFile(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$relativePath');
  }

  /// Returns the absolute path string for a relative path.
  static Future<String> getFullPath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$relativePath';
  }
}
