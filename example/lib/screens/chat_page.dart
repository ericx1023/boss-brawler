import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../main.dart'; // For App.title
import '../../gemini_api_key.dart'; // Adjusted path for api key

// Define your desired system prompt here
const String negotiationCoachSystemPrompt = """
Play a role of a tough negotiation opponent to simulate real life negotiation situation. 
Keep your responses concise and mean. 
You will reject the user, give a brief random reason.
""";

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: LlmChatView(
          provider: GeminiProvider(
            model: GenerativeModel(
              model: 'gemini-2.0-flash',
              apiKey: geminiApiKey,
              systemInstruction: Content.system(negotiationCoachSystemPrompt),
            ),
          ),
        ),
      );
} 