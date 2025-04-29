import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../gemini_api_key.dart';

/// Service for converting text to speech using Hugging Face Nari API.
class TtsService {
  /// Synthesizes speech from [text] and returns the JSON response.
  static Future<Map<String, dynamic>> synthesize(String text) async {
    debugPrint('TtsService: sending TTS request.');
    final url = Uri.parse('https://router.huggingface.co/fal-ai/fal-ai/dia-tts');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $huggingfaceApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inputs': text}),
    );
    debugPrint('TtsService: received response status ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('TTS request failed: ${response.statusCode}');
    }
    debugPrint('TtsService: decoding response body');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
} 