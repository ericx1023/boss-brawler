import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender { user, model } // Or use String for more flexibility

class ChatMessage {
  final String id; // Firestore document ID
  final String text;
  final MessageSender sender; // Identifies who sent the message
  final Timestamp timestamp; // Time the message was created
  final String? messageType; // Optional: e.g., 'text', 'image', 'error'

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.messageType,
  });

  // Factory constructor from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '', // Provide default value
      sender: _senderFromString(data['sender'] ?? 'user'), // Handle potential null
      timestamp: data['timestamp'] ?? Timestamp.now(), // Provide default value
      messageType: data['messageType'],
    );
  }

  // Method to convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'sender': _senderToString(sender),
      'timestamp': timestamp,
      if (messageType != null) 'messageType': messageType,
    };
  }

  // Helper to convert string to enum
  static MessageSender _senderFromString(String sender) {
    return MessageSender.values.firstWhere(
      (e) => e.toString().split('.').last == sender,
      orElse: () => MessageSender.user, // Default if string doesn't match
    );
  }

  // Helper to convert enum to string
  static String _senderToString(MessageSender sender) {
    return sender.toString().split('.').last;
  }
} 