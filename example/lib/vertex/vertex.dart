// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

// Import the new files
import '../prompt_manager.dart';
import '../coaching_vertex_provider.dart'; // Assuming this file exists at lib/coaching_vertex_provider.dart

// from `flutterfire config`: https://firebase.google.com/docs/flutter/setup
import '../firebase_options.dart';

// Define the system prompt
const String negotiationCoachSystemPrompt = """
Play a role of a tough negotiation opponent. 
Keep your responses concise and mean. 
You will reply No, to reject the user, give a brief random reason.
""";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  static const title = 'Example: Firebase Vertex AI Coach'; // Updated title

  const App({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(title: title, home: ChatPage());
}

class ChatPage extends StatefulWidget { // Change to StatefulWidget to hold state
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> { // State class
  late final GenerativeModel _model;
  late final PromptManager _promptManager;
  late final CoachingVertexProvider _coachProvider;

  @override
  void initState() {
    super.initState();
    // Initialize the model and managers
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-pro-preview-03-25',
      // Location might need to be configured differently or might use a default
      systemInstruction: Content.system(negotiationCoachSystemPrompt), // Add system instruction here
    );
    _promptManager = PromptManager();
    _coachProvider = CoachingVertexProvider(
      model: _model,
      promptManager: _promptManager,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(App.title)),
    body: LlmChatView(
      // Use the new CoachingVertexProvider
      provider: _coachProvider,
      // Keeping the rest as it was, assuming LlmChatView handles message display etc.
    ),
  );
}
