import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'chat_service.dart';
import 'analysis_service.dart';
import 'list_model_service.dart';

/// Service to send messages through chat provider with command interception and analysis
class MessageSenderService {
  final ChatService chatService;
  final AnalysisService analysisService;

  MessageSenderService({
    required this.chatService,
    required this.analysisService,
  });

  /// Sends a user message, intercepts commands, streams LLM responses, and triggers analysis
  Stream<String> sendMessage(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    final provider = chatService.provider;

    // Intercept '/listmodels' command
    if (prompt.trim() == '/listmodels') {
      final listText = await listModelsAsString();
      final listMsg = ChatMessage.llm();
      listMsg.text = listText;
      provider.history = [...provider.history, listMsg];
      yield listText;
      return;
    }

    // Step 1: Add the user message to history
    final userMsg = ChatMessage.user(prompt, attachments);
    provider.history = [...provider.history, userMsg];
    provider.notifyListeners();

    // Step 2: Only perform analysis if user has sent >= 2 messages
    final userMessageCount = provider.history.where((msg) => msg.origin.isUser).length;
    if (userMessageCount >= 2) {
      // Add a placeholder for analysis feedback
      final analysisPlaceholder = ChatMessage.llm();
      provider.history = [...provider.history, analysisPlaceholder];
      provider.notifyListeners();
      try {
        final analysisMsg = await analysisService.analyzeMessages(provider.history.toList());
        analysisPlaceholder.text = analysisMsg.text;
        provider.notifyListeners();
        yield analysisMsg.text ?? '';
      } catch (e) {
        debugPrint('Analysis failed: $e');
        // Remove placeholder on failure
        provider.history = provider.history.where((msg) => msg != analysisPlaceholder).toList();
        provider.notifyListeners();
      }
    }

    // Step 3: After analysis, send to negotiation LLM and stream response
    debugPrint('Sending message to negotiation LLM: $prompt');
    // Add placeholder for LLM response
    final llmPlaceholder = ChatMessage.llm();
    provider.history = [...provider.history, llmPlaceholder];
    provider.notifyListeners();
    // Use generateStream to avoid duplicating user message in history
    await for (final chunk in provider.generateStream(prompt, attachments: attachments)) {
      llmPlaceholder.append(chunk);
      yield chunk;
    }
    provider.notifyListeners();
  }
} 