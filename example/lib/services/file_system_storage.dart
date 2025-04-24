import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:uuid/uuid.dart';

import 'chat_history_storage.dart';

/// Implementation of ChatHistoryStorage that uses the file system
/// for native platforms (Android, iOS, macOS, Windows, Linux)
class FileSystemStorage implements ChatHistoryStorage {
  static const String _sessionsFileName = 'sessions.json';
  static const String _activeSessionFileName = 'active_session.txt';
  
  io.Directory? _sessionsDir;
  String? _activeSessionUuid;
  
  /// Initialize the file system storage
  FileSystemStorage();
  
  /// Gets the directory for a specific session
  Future<io.Directory> _getSessionDir(String uuid) async {
    final sessionsDir = await _getSessionsDir();
    final sessionDir = io.Directory(path.join(sessionsDir.path, uuid));
    await sessionDir.create(recursive: true);
    return sessionDir;
  }
  
  /// Gets the base directory for all sessions
  Future<io.Directory> _getSessionsDir() async {
    if (_sessionsDir == null) {
      final temp = await pp.getTemporaryDirectory();
      _sessionsDir = io.Directory(path.join(temp.path, 'chat-sessions'));
      await _sessionsDir!.create(recursive: true);
    }
    return _sessionsDir!;
  }
  
  /// Gets the file for a specific message index in a session
  Future<io.File> _messageFile(String sessionUuid, int messageNo) async {
    final sessionDir = await _getSessionDir(sessionUuid);
    final fileName = path.join(
      sessionDir.path,
      'message-${messageNo.toString().padLeft(3, '0')}.json',
    );
    return io.File(fileName);
  }
  
  /// Gets the active session UUID
  Future<String?> _getActiveSessionUuid() async {
    if (_activeSessionUuid != null) return _activeSessionUuid;
    
    final file = await _getActiveSessionFile();
    if (await file.exists()) {
      _activeSessionUuid = await file.readAsString();
      return _activeSessionUuid;
    }
    
    return null;
  }
  
  /// Sets the active session UUID
  Future<void> _setActiveSessionUuid(String uuid) async {
    final file = await _getActiveSessionFile();
    await file.writeAsString(uuid);
    _activeSessionUuid = uuid;
  }
  
  /// Gets the active session file
  Future<io.File> _getActiveSessionFile() async {
    final sessionsDir = await _getSessionsDir();
    return io.File(path.join(sessionsDir.path, _activeSessionFileName));
  }
  
  /// Gets the sessions metadata file
  Future<io.File> _getSessionsFile() async {
    final sessionsDir = await _getSessionsDir();
    return io.File(path.join(sessionsDir.path, _sessionsFileName));
  }
  
  /// Saves session metadata
  Future<void> _saveSessionMetadata(ChatSession session) async {
    final sessionsFile = await _getSessionsFile();
    final List<Map<String, dynamic>> sessionsData = await _loadSessionsMetadata();
    
    // Find and update or add the session metadata
    bool updated = false;
    for (var i = 0; i < sessionsData.length; i++) {
      if (sessionsData[i]['uuid'] == session.uuid) {
        sessionsData[i] = {
          'uuid': session.uuid,
          'timestamp': session.timestamp,
          'count': session.messages.length,
        };
        updated = true;
        break;
      }
    }
    
    if (!updated) {
      sessionsData.add({
        'uuid': session.uuid,
        'timestamp': session.timestamp,
        'count': session.messages.length,
      });
    }
    
    // Sort by timestamp (newest first)
    sessionsData.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    
    // Save to file
    await sessionsFile.writeAsString(JsonEncoder.withIndent('  ').convert(sessionsData));
  }
  
  /// Loads session metadata
  Future<List<Map<String, dynamic>>> _loadSessionsMetadata() async {
    final sessionsFile = await _getSessionsFile();
    if (!await sessionsFile.exists()) {
      return [];
    }
    
    final content = await sessionsFile.readAsString();
    if (content.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonData = jsonDecode(content);
      return jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error parsing sessions metadata: $e');
      return [];
    }
  }
  
  @override
  Future<ChatSession> createSession(List<ChatMessage> messages) async {
    final uuid = const Uuid().v4();
    final session = ChatSession(
      uuid: uuid,
      messages: messages,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    await saveSession(session);
    await _setActiveSessionUuid(uuid);
    
    return session;
  }
  
  @override
  Future<void> saveSession(ChatSession session) async {
    debugPrint('Saving session with UUID: ${session.uuid}, messages: ${session.messages.length}');
    
    // Get session directory
    final sessionDir = await _getSessionDir(session.uuid);
    
    // Clean up existing messages
    if (await sessionDir.exists()) {
      for (final file in await sessionDir.list().toList()) {
        if (file.path.endsWith('.json')) {
          await file.delete();
        }
      }
    }
    
    // Save each message
    for (var i = 0; i < session.messages.length; i++) {
      final file = await _messageFile(session.uuid, i);
      final map = session.messages[i].toJson();
      final json = JsonEncoder.withIndent('  ').convert(map);
      await file.writeAsString(json);
    }
    
    // Update session metadata
    await _saveSessionMetadata(session);
  }
  
  @override
  Future<ChatSession?> getSession(String uuid) async {
    final sessionMetadata = await _loadSessionsMetadata();
    Map<String, dynamic>? metadata;
    
    for (final data in sessionMetadata) {
      if (data['uuid'] == uuid) {
        metadata = data;
        break;
      }
    }
    
    if (metadata == null) {
      return null;
    }
    
    // Load messages for this session
    final messages = <ChatMessage>[];
    final sessionDir = await _getSessionDir(uuid);
    
    if (await sessionDir.exists()) {
      for (var i = 0; ; i++) {
        final file = await _messageFile(uuid, i);
        if (!await file.exists()) break;
        
        final content = await file.readAsString();
        try {
          final map = jsonDecode(content);
          messages.add(ChatMessage.fromJson(map));
        } catch (e) {
          debugPrint('Error parsing message file: $e');
        }
      }
    }
    
    return ChatSession(
      uuid: uuid,
      messages: messages,
      timestamp: metadata['timestamp'] as int,
    );
  }
  
  @override
  Future<List<ChatSession>> getAllSessions() async {
    final sessionMetadata = await _loadSessionsMetadata();
    final sessions = <ChatSession>[];
    
    for (final metadata in sessionMetadata) {
      final session = await getSession(metadata['uuid'] as String);
      if (session != null) {
        sessions.add(session);
      }
    }
    
    return sessions;
  }
  
  @override
  Future<void> deleteSession(String uuid) async {
    // Delete session directory
    final sessionDir = await _getSessionDir(uuid);
    if (await sessionDir.exists()) {
      await sessionDir.delete(recursive: true);
    }
    
    // Update metadata
    final sessionsMetadata = await _loadSessionsMetadata();
    sessionsMetadata.removeWhere((session) => session['uuid'] == uuid);
    final sessionsFile = await _getSessionsFile();
    await sessionsFile.writeAsString(JsonEncoder.withIndent('  ').convert(sessionsMetadata));
    
    // Update active session if needed
    final activeUuid = await _getActiveSessionUuid();
    if (activeUuid == uuid) {
      if (sessionsMetadata.isNotEmpty) {
        await _setActiveSessionUuid(sessionsMetadata.first['uuid'] as String);
      } else {
        final activeFile = await _getActiveSessionFile();
        if (await activeFile.exists()) {
          await activeFile.delete();
        }
        _activeSessionUuid = null;
      }
    }
  }
  
  @override
  Future<void> deleteAllSessions() async {
    // Delete all session directories
    final sessionsDir = await _getSessionsDir();
    if (await sessionsDir.exists()) {
      await sessionsDir.delete(recursive: true);
      _sessionsDir = null;
      await _getSessionsDir(); // Recreate empty directory
    }
    
    // Clear active session
    final activeFile = await _getActiveSessionFile();
    if (await activeFile.exists()) {
      await activeFile.delete();
    }
    _activeSessionUuid = null;
  }
  
  // ---- Legacy methods for backward compatibility ----
  
  @override
  Future<void> saveHistory(List<ChatMessage> history) async {
    debugPrint('Legacy saveHistory called with ${history.length} messages');
    
    try {
      // 不再檢查現有會話，直接創建新會話
      await createSession(history);
      debugPrint('Created new chat session with ${history.length} messages');
    } catch (e) {
      debugPrint('Error in legacy saveHistory: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> saveMessage(ChatMessage message, int index) async {
    debugPrint('Legacy saveMessage called for index $index');
    
    // Get current active session or create new one with empty messages
    String? activeUuid = await _getActiveSessionUuid();
    List<ChatMessage> messages = [];
    
    if (activeUuid != null) {
      final session = await getSession(activeUuid);
      if (session != null) {
        messages = session.messages;
      }
    } else {
      // Create new session if none exists
      activeUuid = const Uuid().v4();
      await _setActiveSessionUuid(activeUuid);
    }
    
    // Ensure index is valid
    while (messages.length <= index) {
      messages.add(ChatMessage.llm());
    }
    
    // Update message at index
    messages[index] = message;
    
    // Save updated messages
    await saveHistory(messages);
  }
  
  @override
  Future<List<ChatMessage>> loadHistory() async {
    // Get active session or most recent one
    String? activeUuid = await _getActiveSessionUuid();
    
    if (activeUuid != null) {
      final session = await getSession(activeUuid);
      if (session != null) {
        return session.messages;
      }
    }
    
    // No active session, try to get the most recent one
    final sessions = await getAllSessions();
    if (sessions.isNotEmpty) {
      final mostRecent = sessions.first;
      await _setActiveSessionUuid(mostRecent.uuid);
      return mostRecent.messages;
    }
    
    return [];
  }
  
  @override
  Future<void> clearHistory() async {
    await deleteAllSessions();
  }
} 