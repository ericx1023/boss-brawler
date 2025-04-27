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

    debugPrint('Sending message: $prompt');
    // Yield streamed response chunks
    await for (final chunk in provider.sendMessageStream(prompt, attachments: attachments)) {
      yield chunk;
    }

    // After AI response completes, trigger analysis if user has sent >= 2 messages
    final userMessageCount = provider.history.where((msg) => msg.origin.isUser).length;
    if (userMessageCount >= 2) {
      try {
        final analysisMsg = await analysisService.analyzeMessages(provider.history.toList());
        provider.history = [...provider.history, analysisMsg];
        yield analysisMsg.text ?? '';
      } catch (e) {
        debugPrint('Analysis failed: $e');
      }
    }
  }
} 