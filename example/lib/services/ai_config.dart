import 'package:google_generative_ai/google_generative_ai.dart';
import '../gemini_api_key.dart';

/// Centralized configuration for AI services
class AiConfig {
  static const String defaultModel = 'gemini-2.0-flash';
  
  /// Creates a GenerativeModel for main chat with system instructions
  static GenerativeModel createChatModel(String systemPrompt) {
    return GenerativeModel(
      model: defaultModel,
      apiKey: geminiApiKey,
      systemInstruction: Content.system(systemPrompt),
    );
  }
  
  /// Creates a GenerativeModel for STT without system instructions
  static GenerativeModel createSttModel() {
    return GenerativeModel(
      model: defaultModel,
      apiKey: geminiApiKey,
      // No systemInstruction for STT
    );
  }
  
  /// Creates a GenerativeModel for scenario generation
  static GenerativeModel createScenarioModel(String systemPrompt) {
    return GenerativeModel(
      model: defaultModel,
      apiKey: geminiApiKey,
      systemInstruction: Content.system(systemPrompt),
    );
  }
} 