import 'dart:convert';
import 'package:http/http.dart' as http;
import '../gemini_api_key.dart';

/// Fetch available models from Generative Language API
Future<List<dynamic>> fetchModels() async {
  final uri = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/models',
    {'key': geminiApiKey},
  );

  final response = await http.get(uri, headers: {
    'Content-Type': 'application/json',
  });

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data['models'] as List<dynamic>;
  } else {
    throw Exception('Failed to list models: ${response.statusCode} ${response.body}');
  }
}

/// Return formatted string listing models and their supported methods
Future<String> listModelsAsString() async {
  final models = await fetchModels();
  final buffer = StringBuffer();
  buffer.writeln('Available Models:');
  for (final m in models) {
    final name = m['name'];
    final methods = m['supportedGenerationMethods'];
    buffer.writeln('- $name (supports: $methods)');
  }
  return buffer.toString();
}
