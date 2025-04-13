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

// Convert to StatefulWidget
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Add TextEditingController for context input
  final _contextController = TextEditingController();
  // State variable for the combined system prompt
  late String _currentSystemPrompt;

  @override
  void initState() {
    super.initState();
    // Initialize the prompt
    _currentSystemPrompt = negotiationCoachSystemPrompt;
    // Add listener to update prompt dynamically
    _contextController.addListener(_updateSystemPrompt);
  }

  void _updateSystemPrompt() {
    setState(() {
      // Combine base prompt with user context
      _currentSystemPrompt = negotiationCoachSystemPrompt + 
                             "\n\nAdditional Context Provided by User:\n" + 
                             _contextController.text;
    });
  }

  @override
  void dispose() {
    // Remove listener before disposing controller
    _contextController.removeListener(_updateSystemPrompt);
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        // Use Column to arrange TextField and ChatView
        body: Column(
          children: [
            // Add Padding and TextField for context input
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _contextController,
                decoration: const InputDecoration(
                  hintText: 'Enter additional context to refine the scenario...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            // Add a divider
            const Divider(height: 1),
            // Make LlmChatView take remaining space
            Expanded(
              child: LlmChatView(
                provider: GeminiProvider(
                  model: GenerativeModel(
                    model: 'gemini-1.5-flash', // Updated model
                    apiKey: geminiApiKey,
                    // Use the state variable for the system instruction
                    systemInstruction: Content.system(_currentSystemPrompt),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
} 