import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_session.dart';
import '../models/chat_message.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<ConversationSession> _sessionsRef;

  FirestoreService() {
    _sessionsRef = _db.collection('conversation_sessions').withConverter<ConversationSession>(
          fromFirestore: (snapshots, _) => ConversationSession.fromFirestore(snapshots),
          toFirestore: (session, _) => session.toFirestore(),
        );
  }

  // --- Session Management ---

  /// Creates a new conversation session in Firestore.
  Future<DocumentReference<ConversationSession>> createNewSession() async {
    final newSession = ConversationSession(
      id: '', // Firestore will generate the ID
      createdAt: Timestamp.now(),
    );
    // Add the session and return the reference
    return await _sessionsRef.add(newSession);
  }

  /// Retrieves a list of all conversation sessions.
  Future<List<ConversationSession>> listSessions() async {
    final querySnapshot = await _sessionsRef.orderBy('createdAt', descending: true).get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Retrieves a specific session by its ID.
  Future<ConversationSession?> getSession(String sessionId) async {
    final docSnapshot = await _sessionsRef.doc(sessionId).get();
    return docSnapshot.data();
  }

  // --- Message Management ---

  /// Adds a new message to a specific conversation session.
  Future<void> addMessageToSession(String sessionId, ChatMessage message) async {
    final messageRef = _sessionsRef
        .doc(sessionId)
        .collection('messages')
        .withConverter<ChatMessage>(
          fromFirestore: (snapshots, _) => ChatMessage.fromFirestore(snapshots),
          toFirestore: (message, _) => message.toFirestore(),
        );
    await messageRef.add(message);
  }

  /// Retrieves all messages for a specific conversation session.
  Stream<List<ChatMessage>> getMessagesForSessionStream(String sessionId) {
    final messagesQuery = _sessionsRef
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Usually show oldest first
        .withConverter<ChatMessage>(
          fromFirestore: (snapshots, _) => ChatMessage.fromFirestore(snapshots),
          toFirestore: (message, _) => message.toFirestore(),
        );

    return messagesQuery.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Retrieves all messages for a specific conversation session once.
  Future<List<ChatMessage>> getMessagesForSessionOnce(String sessionId) async {
     final messagesQuery = _sessionsRef
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Usually show oldest first
        .withConverter<ChatMessage>(
          fromFirestore: (snapshots, _) => ChatMessage.fromFirestore(snapshots),
          toFirestore: (message, _) => message.toFirestore(),
        );
      final querySnapshot = await messagesQuery.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
} 