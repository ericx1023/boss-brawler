import 'package:flutter/material.dart';
import '../services/chat_history_service.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../services/chat_storage_factory.dart';
import '../services/chat_history_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      return '${diff.inMinutes} min ago'; // Shortened for space
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago'; // Shortened
    } else {
      return '${diff.inDays}d ago'; // Shortened
    }
  }

  // Simplified grouping for now, can be expanded as per image
  Map<String, List<ChatSession>> _groupSessions(List<ChatSession> sessions) {
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    // For simplicity, returning all under a generic "Recent" group for now
    // The image shows "Active", "Work", "Fun", "Archived" which needs more logic
    return {'Recent Chats': sessions};
  }

  // Placeholder for tab icons based on image, actual icons might differ
  Widget _getChatIcon(String? firstMessageContent) {
    if (firstMessageContent == null) return const Icon(Icons.chat_bubble_outline);
    if (firstMessageContent.toLowerCase().contains('art')) return const Icon(Icons.palette_outlined);
    if (firstMessageContent.toLowerCase().contains('universe') || firstMessageContent.toLowerCase().contains('astronomy')) return const Icon(Icons.rocket_launch_outlined);
    if (firstMessageContent.toLowerCase().contains('kitchen') || firstMessageContent.toLowerCase().contains('cooking')) return const Icon(Icons.emoji_food_beverage_outlined);
    return const Icon(Icons.chat_bubble_outline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Profile icon and name as per image
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            // Replace with actual user image logic
            backgroundImage: NetworkImage('https://placekitten.com/g/50/50'), // Placeholder
          ),
        ),
        title: const Text('@john_do'), // As per image
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border), // As per image
            onPressed: () {
              // Handle bookmark action
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none), // As per image
            onPressed: () {
              // Handle notifications action
            },
          ),
        ],
      ),
      body: Column( // Use Column to stack New Chat, Tabs, and Chat List
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell( // Wrap with InkWell for tap functionality
              onTap: () async {
                // Create a new empty chat session
                await ChatStorageFactory.createSession(<ChatMessage>[]);
                // Navigate to Chat page
                Navigator.pushNamed(context, '/chat');
              },
              child: Text(
                'New Chat', // As per image
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Chats', // Changed from "Chat History"
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Search icon for chats
          //  Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //   child: TextField(
          //     decoration: InputDecoration(
          //       hintText: 'Search Chats',
          //       prefixIcon: Icon(Icons.search),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(25.0),
          //         borderSide: BorderSide.none,
          //       ),
          //       filled: true,
          //       fillColor: Colors.grey[200], // Adjust color as needed
          //     ),
          //   ),
          // ),
          const SizedBox(height: 8),
          Expanded( // Chat list takes remaining space
            child: FutureBuilder<List<ChatSession>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final sessions = snapshot.data;
                if (sessions == null || sessions.isEmpty) {
                  return const Center(child: Text('No chats yet'));
                }
                // Grouping is simplified here, actual implementation might need more complex logic for tabs
                // final grouped = _groupSessions(sessions);

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final preview = session.messages.isNotEmpty && session.messages.first.text != null
                        ? session.messages.first.text!
                        : 'Empty chat';
                    final date = DateTime.fromMillisecondsSinceEpoch(session.timestamp);
                    
                    // Extracting the title-like part from the preview if possible
                    // This is a simple heuristic and might need refinement
                    String title = preview;
                    if (preview.contains(':')) {
                       title = preview.substring(0, preview.indexOf(':')).trim();
                       if (title.length > 30) { // Keep title somewhat short
                         title = '${title.substring(0,27)}...';
                       }
                    } else if (preview.length > 30) {
                        title = '${preview.substring(0,27)}...';
                    }


                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: _getChatIcon(preview), // Dynamic icon based on content
                        title: Text(
                          title, // Use extracted title
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          preview.replaceFirst(title, '').trim().startsWith(':') ? 
                          preview.replaceFirst(title, '').trim().substring(1).trim() : 
                          preview.replaceFirst(title, '').trim(), // Show rest of preview as subtitle
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(_formatRelativeTime(date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: session.uuid,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Original "New Chat" button - keeping it for now, but the image has "New Chat" as text title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Make button full width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await ChatStorageFactory.createSession(<ChatMessage>[]);
                Navigator.pushNamed(context, '/chat');
              },
            ),
          ),
        ],
      ),
    );
  }
} 