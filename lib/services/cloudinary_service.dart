// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Replace these with your actual Cloudinary details
const String cloudName = 'daadykopk';
const String uploadPreset = 'chatapp_preset';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService(cloudName: cloudName, uploadPreset: uploadPreset);
});

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;
  final Dio _dio = Dio();

  CloudinaryService({required this.cloudName, required this.uploadPreset});

  Future<String?> uploadFile(File file, {String? folder}) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'upload_preset': uploadPreset,
        'resource_type': 'auto',
        if (folder != null) 'folder': folder,
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['secure_url'];
      } else {
        print('Cloudinary Upload Failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Upload Error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null) {
          print('Cloudinary Response Data: ${response.data}');
        }
      }
      return null;
    }
  }

  Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<File?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }
}
