// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaServiceProvider = Provider((ref) => MediaService());

class MediaService {
  final Dio _dio = Dio();

  Future<void> downloadAndSaveMedia(
    String url,
    String fileName, {
    bool isImage = true,
  }) async {
    try {
      // 1. Request permissions
      if (isImage) {
        if (!await Gal.hasAccess()) {
          await Gal.requestAccess();
        }
      } else {
        // For documents, we might need storage permissions on older Android or just manage directories
        if (Platform.isAndroid) {
          if (!await Permission.storage.request().isGranted) {
            // Handle permission denied if needed
          }
        }
      }

      // 2. Determine path
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String savePath = "${directory!.path}/$fileName";

      // 3. Download file
      await _dio.download(url, savePath);

      // 4. Save to gallery if it's an image
      if (isImage) {
        await Gal.putImage(savePath);
        // Optionally delete the temp file after saving to gallery
        // File(savePath).delete();
      }

      print('File downloaded to: $savePath');
    } catch (e) {
      print('Error downloading/saving media: $e');
      rethrow;
    }
  }
}
