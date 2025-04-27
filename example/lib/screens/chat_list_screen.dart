import 'package:flutter/material.dart';
import '../services/chat_history_service.dart';
import '../services/chat_history_storage.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatSession>> _sessionsFuture;
  final ChatHistoryService _historyService = ChatHistoryService();

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _historyService.getAllSessions();
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  Map<String, List<ChatSession>> _groupSessions(List<ChatSession> sessions) {
    final Map<String, List<ChatSession>> grouped = {
      'Today': [],
      'Yesterday': [],
      'This week': [],
      'Older': [],
    };
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (var session in sessions) {
      final date = DateTime.fromMillisecondsSinceEpoch(session.timestamp);
      if (date.isAfter(todayStart)) {
        grouped['Today']!.add(session);
      } else if (date.isAfter(yesterdayStart)) {
        grouped['Yesterday']!.add(session);
      } else if (date.isAfter(weekStart)) {
        grouped['This week']!.add(session);
      } else {
        grouped['Older']!.add(session);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
        title: const Text('Chats'),
      ),
      body: FutureBuilder<List<ChatSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }
          final grouped = _groupSessions(sessions);
          return ListView(
            children: grouped.entries
                .where((e) => e.value.isNotEmpty)
                .expand((entry) => [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...entry.value.map(
                        (session) {
                          final preview = session.messages.isNotEmpty
                              ? (session.messages.first.text ?? 'Empty chat')
                              : 'Empty chat';
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              session.timestamp);
                          return ListTile(
                            title: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_formatRelativeTime(date)),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/chat',
                                arguments: session.uuid,
                              );
                            },
                          );
                        },
                      )
                    ])
                .toList(),
          );
        },
      ),
    );
  }
} 