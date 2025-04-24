import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:uuid/uuid.dart';

import 'chat_history_storage.dart';

/// Implementation of ChatHistoryStorage that uses IndexedDB
/// for web platform storage
class IndexedDBStorage implements ChatHistoryStorage {
  static const String _dbName = 'chat_history_db';
  static const String _storeName = 'messages';
  static const int _dbVersion = 2; // Increment version for schema change
  static const String _historyKey = 'chat_history';
  static const String _activeSessionKey = 'active_session';
  
  Database? _db;
  
  /// Cached active session UUID
  String? _activeSessionUuid;
  
  /// Initialize the IndexedDB storage
  IndexedDBStorage();
  
  /// Open the database connection
  Future<Database> _openDatabase() async {
    if (_db != null) return _db!;
    
    debugPrint('Opening IndexedDB database: $_dbName');
    
    try {
      // Get the IndexedDB factory for browser
      final idbFactory = getIdbFactory();
      if (idbFactory == null) {
        throw Exception('IndexedDB is not supported in this environment');
      }
      
      // Open the database
      _db = await idbFactory.open(_dbName, version: _dbVersion,
        onUpgradeNeeded: (VersionChangeEvent event) {
          debugPrint('Upgrading IndexedDB database from ${event.oldVersion} to ${event.newVersion}');
          final db = event.database;
          
          // Create object store if it doesn't exist
          if (!db.objectStoreNames.contains(_storeName)) {
            db.createObjectStore(_storeName);
            debugPrint('Created object store: $_storeName');
          }
          
          // Handle migration from v1 to v2
          if (event.oldVersion == 1 && event.newVersion == 2) {
            debugPrint('Migrating from single chat history to multi-session model');
            // Migration will happen in the loadHistory method when old format is detected
          }
        }
      );
      
      debugPrint('Successfully opened IndexedDB database');
      return _db!;
      
    } catch (e) {
      debugPrint('Exception opening IndexedDB: $e');
      rethrow;
    }
  }
  
  /// Get the currently active session UUID
  Future<String?> _getActiveSessionUuid() async {
    if (_activeSessionUuid != null) return _activeSessionUuid;
    
    try {
      final db = await _openDatabase();
      final transaction = db.transaction(_storeName, idbModeReadOnly);
      final store = transaction.objectStore(_storeName);
      
      final result = await store.getObject(_activeSessionKey);
      await transaction.completed;
      
      if (result != null) {
        _activeSessionUuid = result as String;
        debugPrint('Found active session UUID: $_activeSessionUuid');
      }
      
      return _activeSessionUuid;
    } catch (e) {
      debugPrint('Error getting active session UUID: $e');
      return null;
    }
  }
  
  /// Set the active session UUID
  Future<void> _setActiveSessionUuid(String uuid) async {
    try {
      final db = await _openDatabase();
      final transaction = db.transaction(_storeName, idbModeReadWrite);
      final store = transaction.objectStore(_storeName);
      
      await store.put(uuid, _activeSessionKey);
      await transaction.completed;
      
      _activeSessionUuid = uuid;
      debugPrint('Set active session UUID: $uuid');
    } catch (e) {
      debugPrint('Error setting active session UUID: $e');
      rethrow;
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
    
    try {
      final db = await _openDatabase();
      final transaction = db.transaction(_storeName, idbModeReadWrite);
      final store = transaction.objectStore(_storeName);
      
      // Get existing sessions list
      final sessionsData = await _getAllSessionsData(store);
      
      // Find and update or add the session
      bool updated = false;
      for (int i = 0; i < sessionsData.length; i++) {
        if (sessionsData[i]['uuid'] == session.uuid) {
          sessionsData[i] = session.toJson();
          updated = true;
          break;
        }
      }
      
      if (!updated) {
        sessionsData.add(session.toJson());
      }
      
      // Save updated sessions array
      await store.put(sessionsData, _historyKey);
      await transaction.completed;
      
      debugPrint('Saved session to IndexedDB');
    } catch (e) {
      debugPrint('Error saving session: $e');
      rethrow;
    }
  }
  
  @override
  Future<ChatSession?> getSession(String uuid) async {
    try {
      final db = await _openDatabase();
      final transaction = db.transaction(_storeName, idbModeReadOnly);
      final store = transaction.objectStore(_storeName);
      
      final sessionsData = await _getAllSessionsData(store);
      await transaction.completed;
      
      for (final sessionData in sessionsData) {
        if (sessionData['uuid'] == uuid) {
          return ChatSession.fromJson(sessionData);
        }
      }
      
      debugPrint('No session found with UUID: $uuid');
      return null;
    } catch (e) {
      debugPrint('Error getting session: $e');
      return null;
    }
  }
  
  @override
  Future<List<ChatSession>> getAllSessions() async {
    try {
      final db = await _openDatabase();
      final transaction = db.transaction(_storeName, idbModeReadOnly);
      final store = transaction.objectStore(_storeName);
      
      final sessionsData = await _getAllSessionsData(store);
      await transaction.completed;
      
      final sessions = <ChatSession>[];
      for (final sessionData in sessionsData) {
        try {
          sessions.add(ChatSession.fromJson(sessionData));
        } catch (e) {
          debugPrint('Error parsing session: $e');
        }
      }
      
      // Sort by timestamp (newest first)
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      debugPrint('Loaded ${sessions.length} sessions from IndexedDB');
      return sessions;
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      return [];
    }
  }
  
  /// Helper method to get all sessions data as List
  Future<List<Map<String, dynamic>>> _getAllSessionsData(ObjectStore store) async {
    final result = await store.getObject(_historyKey);
    
    if (result == null) {
      return [];
    }
    
    // Check if we need to migrate from old format
    if (result is Map) {
      debugPrint('Detected old single-session format, migrating to multi-session array');
      // Convert old format to new format
      final oldHistoryData = Map<String, dynamic>.from(result);
      return [oldHistoryData]; // Wrap in array for new format
    }
    
    // Already in new format (array)
    return List<Map<String, dynamic>>.from(result as List);
  }
  
  @override
  Future<void> deleteSession(String uuid) async {
    try {
      final db = await _openDatabase();
      final transaction = db.transaction(_storeName, idbModeReadWrite);
      final store = transaction.objectStore(_storeName);
      
      final sessionsData = await _getAllSessionsData(store);
      
      // Remove the session with matching UUID
      sessionsData.removeWhere((session) => session['uuid'] == uuid);
      
      // Save updated sessions array
      await store.put(sessionsData, _historyKey);
      await transaction.completed;
      
      // Update active session if deleted
      if (_activeSessionUuid == uuid) {
        if (sessionsData.isNotEmpty) {
          // Set most recent session as active
          await _setActiveSessionUuid(sessionsData.first['uuid']);
        } else {
          _activeSessionUuid = null;
          await store.delete(_activeSessionKey);
        }
      }
      
      debugPrint('Deleted session with UUID: $uuid');
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> deleteAllSessions() async {
    try {
      final db = await _openDatabase();
      final transaction = db.transaction(_storeName, idbModeReadWrite);
      final store = transaction.objectStore(_storeName);
      
      // Delete sessions array and active session key
      await store.delete(_historyKey);
      await store.delete(_activeSessionKey);
      await transaction.completed;
      
      _activeSessionUuid = null;
      
      debugPrint('Deleted all sessions from IndexedDB');
    } catch (e) {
      debugPrint('Error deleting all sessions: $e');
      rethrow;
    }
  }
  
  // ---- Legacy methods for backward compatibility ----
  
  @override
  Future<void> saveHistory(List<ChatMessage> history) async {
    debugPrint('Legacy saveHistory called with ${history.length} messages');
    
    try {
      // Get active session UUID or create new one
      String? activeUuid = await _getActiveSessionUuid();
      
      if (activeUuid != null) {
        // Update existing session
        final session = await getSession(activeUuid);
        if (session != null) {
          final updatedSession = ChatSession(
            uuid: session.uuid,
            messages: history,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          await saveSession(updatedSession);
          return;
        }
      }
      
      // No active session or session not found, create new one
      await createSession(history);
    } catch (e) {
      debugPrint('Error in legacy saveHistory: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> saveMessage(ChatMessage message, int index) async {
    debugPrint('Legacy saveMessage called for index $index');
    
    try {
      // Get current active session or create new one with empty messages
      String? activeUuid = await _getActiveSessionUuid();
      List<ChatMessage> messages = [];
      
      if (activeUuid != null) {
        final session = await getSession(activeUuid);
        if (session != null) {
          messages = session.messages;
        }
      }
      
      // Ensure index is valid
      while (messages.length <= index) {
        messages.add(ChatMessage.llm());
      }
      
      // Update message at index
      messages[index] = message;
      
      // Save updated messages
      await saveHistory(messages);
    } catch (e) {
      debugPrint('Error in legacy saveMessage: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<ChatMessage>> loadHistory() async {
    try {
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
      
      debugPrint('No chat history found');
      return [];
    } catch (e) {
      debugPrint('Error in legacy loadHistory: $e');
      return [];
    }
  }
  
  @override
  Future<void> clearHistory() async {
    debugPrint('Legacy clearHistory called');
    await deleteAllSessions();
  }
} 