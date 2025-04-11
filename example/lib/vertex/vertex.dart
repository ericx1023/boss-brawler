// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

// from `flutterfire config`: https://firebase.google.com/docs/flutter/setup
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  static const title = 'Example: Firebase Vertex AI';

  const App({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(title: title, home: ChatPage());
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(App.title)),
    body: LlmChatView(
      provider: VertexProvider(
        // For details and location availability, see
        // https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/feature-support#non-streaming-text
        model: FirebaseVertexAI.instance.generativeModel(
          model: 'gemini-2.5-pro-preview-03-25',
          // Location might need to be configured differently or might use a default
        ),
      ),
    ),
  );
}
