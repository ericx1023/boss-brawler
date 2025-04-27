import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../gemini_api_key.dart';

/// Service to analyze chat messages using LLM and produce structured feedback
class AnalyzerService {
  /// Singleton instance
  static final AnalyzerService instance = AnalyzerService._internal();

  late final GeminiProvider _provider;
  static const String _analysisSystemPrompt = "Do not analyze any AI responses or earlier parts of the conversation. Only analyze the latest user input and provide constructive feedback based on clarity, assertiveness, flexibility, and empathy.";

  AnalyzerService._internal() {
    _provider = GeminiProvider(
      model: GenerativeModel(
        model: 'gemini-2.5-pro-exp-03-25',
        apiKey: geminiApiKey,
        systemInstruction: Content.system(_analysisSystemPrompt),
      ),
    );
  }

  /// Analyze the conversation history and return an analysis message
  Future<ChatMessage> analyzeMessages(List<ChatMessage> history) async {
    // Extract context and last user message
    final lastUserIndex = history.lastIndexWhere((msg) => msg.origin.isUser);
    final contextMsgs = history.sublist(0, lastUserIndex);
    final lastUserMsg = history[lastUserIndex];

    // Build context for the prompt
    final contextBuffer = StringBuffer();
    for (final msg in contextMsgs) {
      final role = msg.origin.isUser ? 'User' : 'Assistant';
      final text = msg.text?.replaceAll('\n', ' ') ?? '';
      contextBuffer.writeln('$role: $text');
    }
    final prompt = '''Below is the conversation context:








-----

${contextBuffer.toString()}

Please analyze only the latest user input and ignore any AI responses or other messages.
Latest user input: ${lastUserMsg.text}''';

    // Send prompt and collect streaming response
    final chunks = <String>[];
    await for (final chunk in _provider.sendMessageStream(prompt)) {
      chunks.add(chunk);
    }
    final analysisText = chunks.join();

    // Format with marker
    final content = '[ANALYSIS]: $analysisText';

    // Create analysis ChatMessage
    final analysisMsg = ChatMessage.llm();
    analysisMsg.text = content;
    return analysisMsg;
  }
} 