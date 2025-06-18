import 'dart:async'; // Import async for StreamSubscription
import 'dart:convert'; // for JSON decoding
// Import dart:convert for JSON encoding

import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import flutter_markdown
// Import for platform checking

import '../main.dart'; // For App.title
import '../widgets/analysis_feedback_view.dart'; // Import the new widget
import '../widgets/scenario_selector.dart';
import '../widgets/chat_view.dart';
import '../services/ai_config.dart';
import '../services/prompt_builder.dart';
import '../services/chat_service.dart';
import '../services/stt_service.dart';
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

const String _analysisMarker = '[ANALYSIS]:'; // Define the marker

// Convert to StatefulWidget
class ChatPage extends StatefulWidget {
  /// Optional UUID to load specific chat session
  final String? sessionUuid;

  const ChatPage({Key? key, this.sessionUuid}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final GeminiProvider _scenarioProvider;
  bool _isFetchingScenarios = false;
  List<String>? _fetchedScenarios;
  String? _selectedScenario;

  late final PromptBuilder _promptBuilder;
  late final ChatService _chatService;
  late final SttService _sttService;
  late final MessageSenderService _messageSenderService;
  late final AnalysisService _analysisService;
  // store pending user prompt until scenario is chosen
  String? _pendingPrompt;

  @override
  void initState() {
    super.initState();
    _promptBuilder = PromptBuilder(defaultPrompt: negotiationCoachSystemPrompt);
    
    // Don't load previous history if no specific session is requested (new chat)
    final shouldLoadHistory = widget.sessionUuid != null;
    
    _chatService = ChatService(
      promptBuilder: _promptBuilder,
      historyService: ChatHistoryService(),
      loadPreviousHistory: shouldLoadHistory,
    );
    _sttService = SttService();
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
    // Initialize scenario provider for generating negotiation scenarios
    _scenarioProvider = GeminiProvider(
      model: AiConfig.createScenarioModel(scenarioPrompt),
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _sttService.dispose();
    super.dispose();
  }

  // Fetch negotiation scenarios based on initial user input
  Future<void> _handleGenerateScenarios(String prompt) async {
    // Use the passed prompt directly as input for scenario generation
    final input = prompt.trim();
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
        _fetchedScenarios = [...decoded.cast<String>(), 'Skip'];
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
    // const analysisMarker = '[ANALYSIS]:'; // Already defined globally or can be passed if needed
    // No longer need to check for analysisMarker here as ChatHistoryView will use its own builder
    // if (message.startsWith(analysisMarker)) {
    //   final analysisContent = message.substring(analysisMarker.length).trim();
    //   return AnalysisFeedbackView(analysisContent: analysisContent); 
    // }
    // Default rendering using MarkdownBody
    return MarkdownBody(
      data: message,
      selectable: true, // Allow text selection
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: Colors.white), // Set default text color to white
        // You can add more specific styles here if needed for other markdown elements
        // For example, h1, h2, strong, em, etc.
        // strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        // em: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
        // listBullet: TextStyle(color: Colors.white),
        // blockquoteDecoration: BoxDecoration(color: Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(4)),
        // blockquotePadding: EdgeInsets.all(8),
      ),
    );
  }

  // initial send: record prompt, show scenario options, do not send to LLM yet
  Stream<String> _wrappedMessageSender(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    // Dismiss keyboard after user sends message
    FocusScope.of(context).unfocus();
    
    final userMsg = ChatMessage.user(prompt, attachments);
    final hist = _chatService.provider.history;

    // Check if this is the very first message
    if (hist.isEmpty) {
      // For new chats (no sessionUuid), clear active session to ensure new session creation
      if (widget.sessionUuid == null) {
        await _chatService.clearActiveSession();
        // Temporarily remove the history listener to prevent automatic saving during scenario selection
        _chatService.disableHistorySaving();
      }
      
      setState(() { _pendingPrompt = prompt; });
      _chatService.provider.history = [...hist, userMsg];
      _chatService.provider.notifyListeners();
      await _handleGenerateScenarios(prompt);
      // no further yields; wait for scenario selection
    } else {
      // For subsequent messages, add to history and send directly
      _chatService.provider.history = [...hist, userMsg];
      _chatService.provider.notifyListeners();
      yield* _messageSenderService.sendMessage(prompt, attachments: attachments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(App.title, style: TextStyle(color: Colors.white)), // AppBar title white
        backgroundColor: Color(0xFF2C2C2E), // Dark grey AppBar background
        iconTheme: IconThemeData(color: Colors.white), // Ensure back button or other icons are white
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatView(
              provider: _chatService.provider,
              sttService: _sttService.translateAudio, // Use STT service instead of provider
              responseBuilder: _buildResponseWidget,
              messageSender: _wrappedMessageSender,
              analysisMessageBuilder: (context, message) { // Provide the analysisMessageBuilder
                // Ensure message.text is not null before using substring
                final analysisContent = message.text?.substring(_analysisMarker.length).trim() ?? '';
                return AnalysisFeedbackView(analysisContent: analysisContent);
              },
              afterUserMessageBuilder: (context, message) {
                // show scenario selector under the matching user message
                if (_fetchedScenarios != null && message.text == _pendingPrompt) {
                  return ScenarioSelector(
                    scenarios: _fetchedScenarios!,
                    selectedScenario: _selectedScenario,
                    onScenarioChanged: (scenario) {
                      setState(() {
                        _selectedScenario = scenario;
                      });
                      
                      // Only send immediately if it's not the custom scenario
                      if (scenario != null && scenario != 'Custom') {
                        final originalPrompt = _pendingPrompt ?? '';
                        if (scenario.toLowerCase() == 'skip') {
                          // Skip scenario selection, use original prompt
                          setState(() {
                            _fetchedScenarios = null;
                            _selectedScenario = null;
                            _pendingPrompt = null;
                          });
                          _sendCombinedPrompt(originalPrompt);
                        } else {
                          // Update the system prompt with the selected scenario
                          _chatService.updatePrompt(scenario: scenario);
                          
                          setState(() {
                            _fetchedScenarios = null;
                            _selectedScenario = null;
                            _pendingPrompt = null;
                          });
                          // Send just the original user prompt, not the scenario
                          _sendCombinedPrompt(originalPrompt);
                        }
                      }
                    },
                    onContextChanged: (customScenario) {
                      // This is called when user clicks "Use This Scenario" button
                      // Update the system prompt with the custom scenario
                      _chatService.updatePrompt(scenario: customScenario);
                      
                      final originalPrompt = _pendingPrompt ?? '';
                      setState(() {
                        _fetchedScenarios = null;
                        _selectedScenario = null;
                        _pendingPrompt = null;
                      });
                      // Send just the original user prompt, not the scenario
                      _sendCombinedPrompt(originalPrompt);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // helper to send prompt (with scenario) to negotiation LLM
  void _sendCombinedPrompt(String prompt, {Iterable<Attachment> attachments = const []}) {
    // Re-enable history saving now that scenario selection is complete
    if (widget.sessionUuid == null) {
      _chatService.enableHistorySaving();
    }
    _messageSenderService.sendMessage(prompt, attachments: attachments).listen((_) {});
  }
} 