import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/error/app_exceptions.dart';

class CameraService {
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<File> captureFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const PermissionDeniedException('Camera permission denied');
    }

    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile == null) {
      throw const CameraException('No image captured');
    }
    return File(xFile.path);
  }

  Future<File> pickFromGallery() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) {
      throw const CameraException('No image selected');
    }
    return File(xFile.path);
  }
}
