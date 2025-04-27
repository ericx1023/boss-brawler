import 'package:flutter/material.dart';
import '../services/chat_history_service.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../services/chat_storage_factory.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boss Brawler'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('New Chat'),
            onTap: () async {
              // Create a new empty chat session
              await ChatStorageFactory.createSession(<ChatMessage>[]);
              // Navigate to Chat page
              Navigator.pushNamed(context, '/chat');
            },
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat History'),
            onTap: () {
              // Navigate to Chats list screen
              Navigator.pushNamed(context, '/chats');
            },
          ),
          const SizedBox(height: 24),

        ],
      ),
    );
  }
} 