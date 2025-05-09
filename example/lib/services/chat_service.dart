import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../gemini_api_key.dart';
import 'prompt_builder.dart';
import 'chat_history_service.dart';

/// Service to manage the chat provider and system prompt, with history saving.
class ChatService {
  final PromptBuilder promptBuilder;
  final ChatHistoryService _historyService;
  late GeminiProvider provider;
  VoidCallback? _historyListener;

  ChatService({
    required this.promptBuilder,
    required ChatHistoryService historyService,
  }) : _historyService = historyService {
    final initialPrompt = promptBuilder.buildPrompt();
    _initProvider(initialPrompt);
  }

  GeminiProvider _createProvider(String systemPrompt) {
    return GeminiProvider(
      model: GenerativeModel(
        model: 'gemini-2.5-pro-exp-03-25',
        apiKey: geminiApiKey,
        systemInstruction: Content.system(systemPrompt),
      ),
    );
  }

  void _initProvider(String systemPrompt) {
    provider = _createProvider(systemPrompt);
    _historyListener = () =>
        _historyService.saveHistory(provider.history.toList());
    provider.addListener(_historyListener!);

    _historyService.loadHistory().then((history) {
      if (history.isNotEmpty) {
        provider.history = history;
      }
    });
  }

  /// Updates the system prompt and retains existing history.
  void updatePrompt({String? scenario, String? context}) {
    final history = provider.history;
    if (_historyListener != null) {
      provider.removeListener(_historyListener!);
    }
    final newPrompt =
        promptBuilder.buildPrompt(scenario: scenario, context: context);
    _initProvider(newPrompt);
    provider.history = history;
  }
} 