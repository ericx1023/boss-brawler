import 'dart:async'; // Import async for StreamSubscription
import 'dart:convert'; // for JSON decoding
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
import '../services/chat_storage_factory.dart';

// Define your desired system prompt here
const String negotiationCoachSystemPrompt = """
Play a role of a tough negotiation opponent to simulate real life negotiation situation. 
Keep your responses concise and realistic. 
You tend to reject the user, give a reason related to the context.
""";

const String scenarioPrompt = """
Based on the user's initial input about a negotiation situation, generate an array of four most common and relevant negotiation scenarios they might encounter. Each scenario should be a brief, clear title that captures a common obstacle or response they might face.

For example, if a user mentions "salary negotiation with boss", you should return an array of four specific negotiation scenarios like:
["The Boss Challenges Your Value", "The Boss Questions Your Performance", "The Boss Cites Budget Constraints", "The Boss Deflects to Company Policy"]

If a user mentions "negotiating with a client over project scope", you might return:
["Client Requests Additional Features at Same Price", "Client Questions Your Rate Compared to Competitors", "Client Wants Faster Timeline Without Additional Resources", "Client Hesitates Due to Budget Limitations"]

Your response should:
1. Be formatted as a valid JSON array containing exactly 4 string elements
2. Include brief, descriptive titles (3-8 words each) that capture realistic scenarios
3. Be tailored to the specific negotiation context mentioned by the user
4. Cover different types of challenges the user might face
5. Use natural, straightforward language

Return ONLY the JSON array with no additional text, explanations, or formatting.

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
  /// Optional UUID to load specific chat session
  final String? sessionUuid;

  const ChatPage({Key? key, this.sessionUuid}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _initialController = TextEditingController();
  final _contextController = TextEditingController();
  late final GeminiProvider _scenarioProvider;
  bool _isFetchingScenarios = false;
  List<String>? _fetchedScenarios;
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

    // If a specific session UUID is provided, load its history
    if (widget.sessionUuid != null) {
      ChatStorageFactory.getSession(widget.sessionUuid!).then((session) {
        if (session != null) {
          // Override provider history with loaded session
          _chatService.provider.history = session.messages;
        }
      });
    }
    // Update prompt when context changes
    _contextController.addListener(() {
      _chatService.updatePrompt(
        scenario: _selectedScenario,
        context: _contextController.text.trim(),
      );
    });
    // Initialize scenario provider for generating negotiation scenarios
    _scenarioProvider = GeminiProvider(
      model: GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: geminiApiKey,
        systemInstruction: Content.system(scenarioPrompt),
      ),
    );
    // Listen to initial input changes to enable/disable button
    _initialController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _contextController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  // Fetch negotiation scenarios based on initial user input
  Future<void> _handleGenerateScenarios() async {
    final input = _initialController.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _isFetchingScenarios = true;
    });
    try {
      final buffer = StringBuffer();
      await for (final chunk in _scenarioProvider.generateStream(input)) {
        buffer.write(chunk);
      }
      final raw = buffer.toString();
      // Extract JSON array between first '[' and last ']' to remove any markdown fences
      String jsonString;
      final startIdx = raw.indexOf('[');
      final endIdx = raw.lastIndexOf(']');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        jsonString = raw.substring(startIdx, endIdx + 1).trim();
      } else {
        jsonString = raw.trim();
      }
      final List<dynamic> decoded = json.decode(jsonString);
      setState(() {
        _fetchedScenarios = decoded.cast<String>();
      });
    } catch (e) {
      debugPrint('Fetch scenarios failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate scenarios')),
      );
    } finally {
      setState(() {
        _isFetchingScenarios = false;
      });
    }
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
        appBar: AppBar(title: const Text(App.title)),
        body: LlmChatView(
          provider: GeminiProvider(
            model: GenerativeModel(model: 'gemini-2.0-flash', apiKey: geminiApiKey),
          ),
        ),
      );

} 