import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boss Brawler'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to Chat screen
            Navigator.pushNamed(context, '/chat');
          },
          child: const Text('Go to Chat'),
        ),
      ),
    );
  }
} 