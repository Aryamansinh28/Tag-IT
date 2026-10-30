import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class WasteAnalysisService {
  static const String baseUrl =
      'https://tag-it-backend.onrender.com';

  static const Duration requestTimeout = Duration(seconds: 60);

  // Prevent duplicate simultaneous requests for the exact same image URL.
  static final Map<String, Future<Map<String, dynamic>>> _inFlightRequests =
      <String, Future<Map<String, dynamic>>>{};

  // Reuse successful results during this app session.
  static final Map<String, Map<String, dynamic>> _analysisCache =
      <String, Map<String, dynamic>>{};

  static Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    final normalizedUrl = imageUrl.trim();

    if (normalizedUrl.isEmpty) {
      throw ArgumentError('Image URL cannot be empty.');
    }

    final parsedUrl = Uri.tryParse(normalizedUrl);
    if (parsedUrl == null ||
        !parsedUrl.hasScheme ||
        (parsedUrl.scheme != 'https' && parsedUrl.scheme != 'http') ||
        parsedUrl.host.isEmpty) {
      throw ArgumentError('A valid image URL is required.');
    }

    final cached = _analysisCache[normalizedUrl];
    if (cached != null) {
      return Map<String, dynamic>.from(cached);
    }

    final inFlight = _inFlightRequests[normalizedUrl];
    if (inFlight != null) {
      final result = await inFlight;
      return Map<String, dynamic>.from(result);
    }

    final request = _sendAnalysisRequest(normalizedUrl);
    _inFlightRequests[normalizedUrl] = request;

    try {
      final result = await request;
      _analysisCache[normalizedUrl] = Map<String, dynamic>.from(result);
      return Map<String, dynamic>.from(result);
    } finally {
      _inFlightRequests.remove(normalizedUrl);
    }
  }

  static Future<Map<String, dynamic>> _sendAnalysisRequest(
    String imageUrl,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/analyze-waste'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'image_url': imageUrl}),
        )
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'AI analysis failed (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('The backend returned invalid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format from the backend.');
    }

    final dynamic analysis = decoded['analysis'];
    if (decoded['status'] != 'success' || analysis is! Map) {
      throw Exception('The backend response did not contain a valid analysis.');
    }

    return Map<String, dynamic>.from(analysis);
  }
}