import 'dart:async'; // Import async for StreamSubscription
// Import dart:convert for JSON encoding

import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import flutter_markdown
// Import for platform checking

import '../main.dart'; // For App.title
import '../../gemini_api_key.dart'; // Adjusted path for api key
import '../widgets/analysis_feedback_view.dart'; // Import the new widget
import '../widgets/scenario_selector.dart';
import '../widgets/chat_view.dart';
import '../services/prompt_builder.dart';
import '../services/chat_service.dart';
import '../services/message_sender_service.dart';
import '../services/chat_history_service.dart';
import '../services/analysis_service.dart';

// Define your desired system prompt here
const String negotiationCoachSystemPrompt = """
Play a role of a tough negotiation opponent to simulate real life negotiation situation. 
Keep your responses concise and realistic. 
You will reject the user, give a reason related to the context.
""";

// Predefined Scenarios
final List<String> predefinedScenarios = [
  "Salary and Compensation Discussions",
  "Client/Vendor Contract Negotiations",
  "Resource Allocation Negotiations",
  "Conflict Resolution",
  "User Customized", // Added User Customized scenario
];

// Convert to StatefulWidget
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _contextController = TextEditingController();
  String? _selectedScenario;

  late final PromptBuilder _promptBuilder;
  late final ChatService _chatService;
  late final MessageSenderService _messageSenderService;
  late final AnalysisService _analysisService;

  @override
  void initState() {
    super.initState();
    _promptBuilder = PromptBuilder(defaultPrompt: negotiationCoachSystemPrompt);
    _chatService = ChatService(
      promptBuilder: _promptBuilder,
      historyService: ChatHistoryService(),
    );
    _analysisService = AnalysisService();
    _messageSenderService = MessageSenderService(
      chatService: _chatService,
      analysisService: _analysisService,
    );

    // Update prompt when context changes
    _contextController.addListener(() {
      _chatService.updatePrompt(
        scenario: _selectedScenario,
        context: _contextController.text.trim(),
      );
    });
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  // Define the response builder function
  Widget _buildResponseWidget(BuildContext context, String message) {
    const analysisMarker = '[ANALYSIS]:';
    if (message.startsWith(analysisMarker)) {
      final analysisContent = message.substring(analysisMarker.length).trim();
      return AnalysisFeedbackView(analysisContent: analysisContent);
    } else {
      // Default rendering using MarkdownBody
      return MarkdownBody(
        data: message,
        selectable: true, // Allow text selection
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),
          title: const Text(App.title),
        ),
        body: Column(
          children: [
            ScenarioSelector(
              scenarios: predefinedScenarios,
              selectedScenario: _selectedScenario,
              onScenarioChanged: (scenario) {
                setState(() {
                  _selectedScenario = scenario;
                  _chatService.updatePrompt(
                    scenario: scenario,
                    context: _contextController.text.trim(),
                  );
                });
              },
              onContextChanged: (context) {
                _chatService.updatePrompt(
                  scenario: _selectedScenario,
                  context: context,
                );
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ChatView(
                provider: _chatService.provider,
                responseBuilder: _buildResponseWidget,
                messageSender: _messageSenderService.sendMessage,
              ),
            ),
          ],
        ),
      );
} 