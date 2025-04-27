// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import the screens
import 'screens/home_screen.dart';
import 'screens/chat_page.dart';
import 'screens/chat_list_screen.dart';


// Make main async and initialize Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  static const title = 'Nego Dojo';

  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: title,
        // Define the routes
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/chat': (context) => const ChatPage(),
          '/chats': (context) => const ChatListScreen(),
        },
      );
}
