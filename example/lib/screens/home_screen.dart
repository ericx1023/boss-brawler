import 'package:flutter/material.dart';

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
            title: const Text('Chats'),
            onTap: () {
              // Navigate to Chats list screen
              Navigator.pushNamed(context, '/chats');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Start a new chat
          Navigator.pushNamed(context, '/chat/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }
} 