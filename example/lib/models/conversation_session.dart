import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationSession {
  final String id;
  final Timestamp createdAt;
  // Optional: Add other fields like title, userId, etc.
  // final String? title;
  // final String? userId;

  ConversationSession({
    required this.id,
    required this.createdAt,
    // this.title,
    // this.userId,
  });

  // Factory constructor to create a ConversationSession from a Firestore document
  factory ConversationSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ConversationSession(
      id: doc.id,
      createdAt: data['createdAt'] ?? Timestamp.now(), // Provide default value
      // title: data['title'],
      // userId: data['userId'],
    );
  }

  // Method to convert a ConversationSession instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': createdAt,
      // if (title != null) 'title': title,
      // if (userId != null) 'userId': userId,
    };
  }
} 