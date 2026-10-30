
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ImageUploadService {
  // Local development URL for the Python backend.
  // For a physical phone, replace this with your PC's
  // reachable LAN address while both are on the same Wi-Fi.
  static const String backendUrl = 'https://tag-it-backend.onrender.com';

  static Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse('$backendUrl/upload');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Image upload failed (${response.statusCode}): '
        '${response.body}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final imageUrl = data['image_url'] as String?;

    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('The backend did not return an image URL.');
    }

    return imageUrl;
  }
}
