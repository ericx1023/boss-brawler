import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'ai_config.dart';
import 'prompt_builder.dart';
import 'chat_history_service.dart';

/// Service to manage the chat provider and system prompt, with history saving.
class ChatService {
  final PromptBuilder promptBuilder;
  final ChatHistoryService _historyService;
  late GeminiProvider provider;
  late GeminiProvider sttProvider; // Separate provider for speech-to-text
  VoidCallback? _historyListener;

  ChatService({
    required this.promptBuilder,
    required ChatHistoryService historyService,
    bool loadPreviousHistory = true,
  }) : _historyService = historyService {
    final initialPrompt = promptBuilder.buildPrompt();
    _initProvider(initialPrompt, loadPreviousHistory);
    _initSttProvider();
  }

  GeminiProvider _createProvider(String systemPrompt) {
    return GeminiProvider(
      model: AiConfig.createChatModel(systemPrompt),
    );
  }

  GeminiProvider _createSttProvider() {
    // Create a provider without system instructions for speech-to-text
    return GeminiProvider(
      model: AiConfig.createSttModel(),
    );
  }

  void _initProvider(String systemPrompt, bool loadPreviousHistory) {
    provider = _createProvider(systemPrompt);
    _historyListener = () =>
        _historyService.saveHistory(provider.history.toList());
    provider.addListener(_historyListener!);

    if (loadPreviousHistory) {
      _historyService.loadHistory().then((history) {
        if (history.isNotEmpty) {
          provider.history = history;
        }
      });
    }
    // Note: Active session clearing is now handled when user sends first message
  }

  void _initSttProvider() {
    sttProvider = _createSttProvider();
  }

  /// Updates the system prompt and retains existing history.
  void updatePrompt({String? scenario, String? context}) {
    // Preserve existing conversation history
    final history = provider.history;
    if (_historyListener != null) {
      provider.removeListener(_historyListener!);
    }
    // Build the new system prompt including optional scenario and context
    final newPrompt = promptBuilder.buildPrompt(
      scenario: scenario,
      context: context,
    );
    // Create a fresh provider with the updated system prompt without reloading saved history
    provider = _createProvider(newPrompt);
    if (_historyListener != null) {
      provider.addListener(_historyListener!);
    }
    // Reapply the existing history directly
    provider.history = history;
  }

  /// Dispose resources
  void dispose() {
    if (_historyListener != null) {
      provider.removeListener(_historyListener!);
    }
  }

  /// Clear the active session to force creation of a new session
  Future<void> clearActiveSession() async {
    try {
      await _historyService.clearActiveSession();
    } catch (e) {
      debugPrint('Error clearing active session: $e');
    }
  }

  /// Temporarily disable history saving (useful during scenario selection)
  void disableHistorySaving() {
    if (_historyListener != null) {
      provider.removeListener(_historyListener!);
    }
  }

  /// Re-enable history saving
  void enableHistorySaving() {
    if (_historyListener != null) {
      provider.addListener(_historyListener!);
    }
  }

  /// Clear the active session to force creation of a new session
  Future<void> _clearActiveSession() async {
    try {
      await _historyService.clearActiveSession();
    } catch (e) {
      debugPrint('Error clearing active session: $e');
    }
  }
} 