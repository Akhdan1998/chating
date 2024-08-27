import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  MediaService();

  Future<File?> getImageFromGalleryImage() async {
    try {
      final XFile? _file = await _picker.pickImage(source: ImageSource.gallery);
      if (_file != null) {
        return File(_file.path);
      } else {
        return null;
      }
    } on PlatformException catch (e) {
      if (e.code == 'invalid_image') {
        print('Invalid image: ${e.message}');
      } else {
        print('Error picking image from gallery: $e');
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
    return null;
  }

  Future<File?> getImageFromCameraImage() async {
    try {
      final XFile? _file = await _picker.pickImage(source: ImageSource.camera);
      if (_file != null) {
        return File(_file.path);
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
    return null;
  }

  Future getDocumentFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        print('File dipilih: ${file.path}');
      } else {
        print('User tidak memilih file.');
      }
    } catch (e) {
      print('Error memilih file: $e');
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> pickImageFromLibrary() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }

  Future<File?> getVideoFromGallery() async {
    XFile? xFile = await _picker.pickVideo(source: ImageSource.gallery);
    return xFile != null ? File(xFile.path) : null;
  }

  Future<File?> getVideoFromCamera() async {
    XFile? xFile = await _picker.pickVideo(source: ImageSource.camera);
    return xFile != null ? File(xFile.path) : null;
  }

  Future<XFile?> pickVideoFromLibrary() async {
    final ImagePicker _picker = ImagePicker();
    return await _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<XFile?> pickVideoFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    return await _picker.pickVideo(source: ImageSource.camera);
  }
}