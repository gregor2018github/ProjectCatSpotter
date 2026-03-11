import 'package:image_picker/image_picker.dart';

class CameraService {
  static final _picker = ImagePicker();

  static Future<XFile?> takePhoto() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  static Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }
}
