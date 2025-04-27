import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'chat_history_storage.dart';
import 'chat_storage_factory.dart';

/// Service to load and save chat history using underlying storage.
class ChatHistoryService {
  final ChatHistoryStorage _storage = ChatStorageFactory.getStorage();

  /// Load the current active chat history.
  Future<List<ChatMessage>> loadHistory() {
    return _storage.loadHistory();
  }

  /// Save the provided chat history to storage.
  Future<void> saveHistory(List<ChatMessage> history) {
    return _storage.saveHistory(history);
  }

  /// Get all chat sessions.
  Future<List<ChatSession>> getAllSessions() {
    return _storage.getAllSessions();
  }
} 