import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

/// Chat session model to represent a complete conversation
class ChatSession {
  /// Unique identifier for the session
  final String uuid;
  
  /// List of messages in this chat session
  final List<ChatMessage> messages;
  
  /// Timestamp when this session was last updated
  final int timestamp;

  /// Create a new chat session
  ChatSession({
    required this.uuid,
    required this.messages,
    required this.timestamp,
  });

  /// Create a chat session from JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final messagesData = json['messages'] as List;
    final messages = messagesData
        .map((msgJson) => ChatMessage.fromJson(Map<String, dynamic>.from(msgJson as Map)))
        .toList();
    
    return ChatSession(
      uuid: json['uuid'] as String,
      messages: messages,
      timestamp: json['timestamp'] as int,
    );
  }

  /// Convert chat session to JSON
  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'messages': messages.map((msg) => msg.toJson()).toList(),
    'timestamp': timestamp,
    'count': messages.length,
  };
}

/// Abstract interface for chat history storage
/// Implementations will handle platform-specific storage logic
abstract class ChatHistoryStorage {
  /// Save a specific chat session
  Future<void> saveSession(ChatSession session);
  
  /// Create a new chat session
  Future<ChatSession> createSession(List<ChatMessage> messages);
  
  /// Get a specific chat session by UUID
  Future<ChatSession?> getSession(String uuid);
  
  /// Get all chat sessions
  Future<List<ChatSession>> getAllSessions();
  
  /// Delete a specific chat session by UUID
  Future<void> deleteSession(String uuid);
  
  /// Delete all chat sessions
  Future<void> deleteAllSessions();
  
  /// Legacy method: Save the entire chat history (will save to current active session)
  Future<void> saveHistory(List<ChatMessage> history);
  
  /// Legacy method: Save a single message at the specified index (in current active session)
  Future<void> saveMessage(ChatMessage message, int index);
  
  /// Legacy method: Load the current active chat history (last used session)
  Future<List<ChatMessage>> loadHistory();
  
  /// Legacy method: Clear all stored history
  Future<void> clearHistory();
  
  /// Clear the active session to force creation of a new session on next save
  Future<void> clearActiveSession();
} 