import 'package:flutter/material.dart';
import '../services/chat_history_service.dart';

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
            onTap: () {
              // Navigate to Chats list screen
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