import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

import 'chat_history_storage.dart';
import 'file_system_storage.dart';
import 'indexed_db_storage.dart';

/// Factory class for creating the appropriate storage implementation
/// based on the current platform
class ChatStorageFactory {
  /// A singleton instance of the storage
  static ChatHistoryStorage? _instance;

  /// Returns the appropriate storage implementation for the current platform
  static ChatHistoryStorage getStorage() {
    _instance ??= _createStorage();
    return _instance!;
  }
  
  /// Creates a new storage instance based on the current platform
  static ChatHistoryStorage _createStorage() {
    if (UniversalPlatform.isWeb) {
      // Use IndexedDB storage for web platform
      return IndexedDBStorage();
    } else {
      // Use file system storage for native platforms
      return FileSystemStorage();
    }
  }
  
  /// Gets all available chat sessions
  static Future<List<ChatSession>> getAllSessions() {
    return getStorage().getAllSessions();
  }
  
  /// Creates a new chat session
  static Future<ChatSession> createSession(List<ChatMessage> messages) {
    return getStorage().createSession(messages);
  }
  
  /// Gets a specific chat session by UUID
  static Future<ChatSession?> getSession(String uuid) {
    return getStorage().getSession(uuid);
  }
  
  /// Deletes a specific chat session by UUID
  static Future<void> deleteSession(String uuid) {
    return getStorage().deleteSession(uuid);
  }
} 