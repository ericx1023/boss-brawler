import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_history_service.dart';
import '../services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _historyService.getAllSessions();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
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

  String _getUserDisplayName() {
    final user = _authService.currentUser;
    if (user == null) return 'Guest';
    
    if (user.isAnonymous) {
      return 'Free Trial';
    }
    
    // Try to get name from profile first, then from Firebase user
    final profileName = _userProfile?['profile']?['name'];
    if (profileName != null && profileName.isNotEmpty) {
      return '@$profileName';
    }
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return '@${user.displayName!}';
    }
    
    if (user.email != null) {
      final emailPrefix = user.email!.split('@').first;
      return '@$emailPrefix';
    }
    
    return '@user';
  }

  Widget _buildUserAvatar() {
    final user = _authService.currentUser;
    if (user?.photoURL != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user!.photoURL!),
      );
    }
    
    // Default avatar based on user type
    return CircleAvatar(
      backgroundColor: user?.isAnonymous == true ? Colors.orange : Colors.blue,
      child: Icon(
        user?.isAnonymous == true ? Icons.flash_on : Icons.person,
        color: Colors.white,
      ),
    );
  }

  void _showUserMenu() {
    final user = _authService.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User info
            ListTile(
              leading: _buildUserAvatar(),
              title: Text(
                _getUserDisplayName(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.isAnonymous 
                  ? 'Anonymous User' 
                  : user.email ?? 'Signed In',
              ),
            ),
            const Divider(),
            
            // Anonymous user upgrade option
            if (user.isAnonymous) ...[
              ListTile(
                leading: const Icon(Icons.upgrade, color: Colors.green),
                title: const Text('Save Your Progress'),
                subtitle: const Text('Sign in with Google to sync across devices'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await _authService.linkWithGoogle();
                  if (result != null) {
                    _loadUserProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account upgraded successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              const Divider(),
            ],
            
            // Settings (placeholder)
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            
            // Sign out
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () async {
                Navigator.pop(context);
                await _authService.signOut();
                // The AuthWrapper will automatically redirect to auth screen
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Dynamic user avatar
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _showUserMenu,
            child: _buildUserAvatar(),
          ),
        ),
        // Dynamic user name
        title: GestureDetector(
          onTap: _showUserMenu,
          child: Text(_getUserDisplayName()),
        ),
        actions: [
          // Anonymous user upgrade hint
          if (_authService.isAnonymous)
            IconButton(
              icon: const Icon(Icons.upgrade, color: Colors.orange),
              tooltip: 'Save your progress',
              onPressed: () async {
                final result = await _authService.linkWithGoogle();
                if (result != null) {
                  _loadUserProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account upgraded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // Handle bookmark action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarks coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showUserMenu,
          ),
        ],
      ),
      body: Column( // Use Column to stack New Chat, Tabs, and Chat List
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anonymous user banner
          if (_authService.isAnonymous)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You\'re in trial mode. Sign in to save your progress!',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final result = await _authService.linkWithGoogle();
                      if (result != null) {
                        _loadUserProfile();
                      }
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          
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

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final preview = session.messages.isNotEmpty && session.messages.first.text != null
                        ? session.messages.first.text!
                        : 'Empty chat';
                    final date = DateTime.fromMillisecondsSinceEpoch(session.timestamp);
                    
                    // Extracting the title-like part from the preview if possible
                    String title = preview;
                    if (preview.contains(':')) {
                       title = preview.substring(0, preview.indexOf(':')).trim();
                       if (title.length > 30) {
                         title = '${title.substring(0,27)}...';
                       }
                    } else if (preview.length > 30) {
                        title = '${preview.substring(0,27)}...';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: _getChatIcon(preview),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          preview.replaceFirst(title, '').trim().startsWith(':') ? 
                          preview.replaceFirst(title, '').trim().substring(1).trim() : 
                          preview.replaceFirst(title, '').trim(),
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
          // Start new chat button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
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