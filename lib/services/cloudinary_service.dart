// lib/services/cloudinary_service.dart
import 'dart:convert';
import 'dart:io';

// Generate SHA-1 signature
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Untuk XFile
import 'package:path/path.dart' as path;

class CloudinaryService {
  final String _cloudName = 'doacsjhtn';
  final String _apiKey = '318348356822436';
  final String _apiSecret = 'nI1o5tJmL8NuCrflJtV0EPwJNGk';
  final String _uploadPreset = 'kasirpro_qris';

  // Method utama yang mendukung File, XFile, dan Uint8List
  Future<Map<String, dynamic>?> uploadImage(
    dynamic imageFile, {
    String folder = 'kasirpro',
  }) async {
    try {
      // Check jika di web
      if (kIsWeb) {
        // Untuk web, imageFile harus XFile atau Uint8List
        if (imageFile is XFile) {
          return await _uploadFromXFile(imageFile, folder: folder);
        } else if (imageFile is Uint8List) {
          return await _uploadFromBytes(imageFile, folder: folder);
        } else {
          throw Exception('Untuk web, gunakan XFile atau Uint8List');
        }
      } else {
        // Untuk mobile, bisa File atau XFile
        if (imageFile is File) {
          return await _uploadFromFile(imageFile, folder: folder);
        } else if (imageFile is XFile) {
          // Konversi XFile ke File untuk mobile
          final File file = File(imageFile.path);
          return await _uploadFromFile(file, folder: folder);
        } else {
          throw Exception('Tipe file tidak didukung');
        }
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Upload dari File (untuk mobile)
  Future<Map<String, dynamic>?> _uploadFromFile(
    File imageFile, {
    String folder = 'kasirpro',
  }) async {
    try {
      // Check file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File terlalu besar. Maksimal 5MB');
      }

      // Create upload URL
      final uploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      // Prepare multipart request
      var request =
          http.MultipartRequest('POST', uploadUrl)
            ..fields['upload_preset'] = _uploadPreset
            ..fields['folder'] = folder
            ..fields['api_key'] = _apiKey
            ..fields['timestamp'] =
                (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      // Add image file
      var fileStream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      var multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: path.basename(imageFile.path),
      );

      request.files.add(multipartFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Cloudinary upload error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in _uploadFromFile: $e');
      return null;
    }
  }

  // Upload dari XFile (untuk web dan mobile)
  Future<Map<String, dynamic>?> _uploadFromXFile(
    XFile xFile, {
    String folder = 'kasirpro',
  }) async {
    try {
      // Get file size untuk web
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        return await _uploadFromBytes(
          bytes,
          folder: folder,
          fileName: xFile.name,
        );
      } else {
        // Untuk mobile, konversi ke File
        final File file = File(xFile.path);
        return await _uploadFromFile(file, folder: folder);
      }
    } catch (e) {
      print('Error in _uploadFromXFile: $e');
      return null;
    }
  }

  // Upload dari bytes (untuk web)
  Future<Map<String, dynamic>?> _uploadFromBytes(
    Uint8List bytes, {
    String folder = 'kasirpro',
    String? fileName,
  }) async {
    try {
      // Check file size (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('File terlalu besar. Maksimal 5MB');
      }

      // Create upload URL
      final uploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      // Prepare multipart request
      var request =
          http.MultipartRequest('POST', uploadUrl)
            ..fields['upload_preset'] = _uploadPreset
            ..fields['folder'] = folder
            ..fields['api_key'] = _apiKey
            ..fields['timestamp'] =
                (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      // Add image file dari bytes
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename:
            fileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      request.files.add(multipartFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Cloudinary upload error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in _uploadFromBytes: $e');
      return null;
    }
  }

  // Method alternative untuk compatibility
  Future<Map<String, dynamic>?> uploadImageSimple(
    dynamic imageFile, {
    String folder = 'kasirpro',
  }) async {
    try {
      // Create upload URL
      final uploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      var request =
          http.MultipartRequest('POST', uploadUrl)
            ..fields['upload_preset'] = _uploadPreset
            ..fields['folder'] = folder;

      // Handle berbeda tipe file
      if (imageFile is File) {
        // Untuk File
        var multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        );
        request.files.add(multipartFile);
      } else if (imageFile is XFile) {
        // Untuk XFile
        final bytes = await imageFile.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        );
        request.files.add(multipartFile);
      } else if (imageFile is Uint8List) {
        // Untuk Uint8List
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageFile,
          filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      } else {
        throw Exception('Tipe file tidak didukung');
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error in simple upload: $e');
      return null;
    }
  }

  // Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final String toSign =
          "public_id=$publicId&timestamp=$timestamp$_apiSecret";

      final signature = sha1.convert(utf8.encode(toSign)).toString();

      final deleteUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
      );

      final response = await http.post(
        deleteUrl,
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
