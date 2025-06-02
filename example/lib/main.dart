// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

// Import the screens
import 'screens/home_screen.dart';
import 'screens/chat_page.dart';
import 'screens/chat_list_screen.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_storage_factory.dart';
import 'services/ios_config_checker.dart';

// Make main async and initialize Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Debug: Clean up duplicate sessions on app start (remove this in production)
  if (kDebugMode) {
    try {
      await ChatStorageFactory.cleanupDuplicateSessions();
      debugPrint('Cleaned up duplicate sessions on app start');
    } catch (e) {
      debugPrint('Error cleaning up sessions on start: $e');
    }
    
    // Check iOS configuration for Google Sign-In
    try {
      await IOSConfigChecker.printConfigurationReport();
    } catch (e) {
      debugPrint('Error checking iOS configuration: $e');
    }
  }

  runApp(const App());
}

class App extends StatelessWidget {
  static const title = 'Boss Brawler';

  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: title,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          canvasColor: Colors.black,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF3A3A3C),
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        // Use AuthWrapper to handle authentication state
        home: const AuthWrapper(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/chat': (context) {
            // Load specific chat session if UUID argument is provided
            final args = ModalRoute.of(context)!.settings.arguments;
            final sessionUuid = args is String ? args : null;
            return ChatPage(sessionUuid: sessionUuid);
          },
          '/chats': (context) => const ChatListScreen(),
        },
      );
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        // User is signed in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // User is not signed in
        return const AuthScreen();
      },
    );
  }
}
