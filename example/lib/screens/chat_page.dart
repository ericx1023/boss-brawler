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
import '../services/chat_history_storage.dart'; // Import the storage abstraction
import '../services/chat_storage_factory.dart'; // Import the factory
import '../services/analyzer_service.dart'; // Import analyzer service
import '../services/list_model_service.dart'; // Import list models service

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
  // Add TextEditingController for context input
  final _contextController = TextEditingController();
  // State variable for the combined system prompt
  late String _currentSystemPrompt;
  String? _selectedScenario; // Nullable string for selected scenario

  late GeminiProvider _provider; // Make provider mutable
  late ChatHistoryStorage _storage; // Add storage field

  @override
  void initState() {
    super.initState();
    _currentSystemPrompt = negotiationCoachSystemPrompt;

    // Initialize storage using the factory
    _storage = ChatStorageFactory.getStorage();

    _updateSystemPrompt();

    _contextController.addListener(_updateSystemPrompt);
    // Don't add listener here as the provider is recreated in _updateSystemPrompt
    
    // Load history using the storage abstraction
    _loadHistory();
  }

  void _updateSystemPrompt() {
    setState(() {
      // Build the system prompt dynamically using StringBuffer for efficiency
      final promptBuilder = StringBuffer(negotiationCoachSystemPrompt);

      String scenarioSection = "";
      if (_selectedScenario != null && _selectedScenario!.isNotEmpty) {
        scenarioSection = "Selected Scenario: $_selectedScenario";
      }

      String contextSection = "";
      if (_contextController.text.trim().isNotEmpty) {
        contextSection =
            "Additional Context Provided by User:\n${_contextController.text.trim()}";
      }

      // Add sections only if they exist, with appropriate spacing
      if (scenarioSection.isNotEmpty || contextSection.isNotEmpty) {
        promptBuilder.write("\n\n"); // Add a separator line
        if (scenarioSection.isNotEmpty) {
          promptBuilder.writeln(scenarioSection); // Use writeln for newline
          if (contextSection.isNotEmpty) {
            promptBuilder.write("\n"); // Add space between sections if both exist
          }
        }
        if (contextSection.isNotEmpty) {
          promptBuilder.writeln(contextSection); // Use writeln for newline
        }
      }

      _currentSystemPrompt = promptBuilder.toString().trim(); // Get the final string and trim

      // Remove listener from old provider if it exists
      try {
        _provider.removeListener(_saveHistory);
      } catch (e) {
        // Provider might not be initialized yet
        debugPrint('No previous provider to remove listener from');
      }

      // Recreate the provider with the new system instruction
      debugPrint('Creating GeminiProvider');
      _provider = GeminiProvider(
        model: GenerativeModel(
          model: 'gemini-2.5-pro-exp-03-25', // Or your preferred model
          apiKey: geminiApiKey,
          systemInstruction: Content.system(_currentSystemPrompt), // Use the constructed prompt
        ),
      );
      debugPrint('GeminiProvider created');
      
      // Add listener to the new provider
      debugPrint('Adding listener to new provider');
      _provider.addListener(_saveHistory);
    });
  }


  // --- Custom Message Sender ---
  Stream<String> _messageSender(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    // Intercept '/listmodels' command to display available models
    if (prompt.trim() == '/listmodels') {
      final listText = await listModelsAsString();
      final listMsg = ChatMessage.llm();
      listMsg.text = listText;
      _provider.history = [..._provider.history, listMsg];
      yield listText;
      return;
    }
    debugPrint('Sending message: $prompt');
    // Forward user message and assistant response
    await for (final chunk in _provider.sendMessageStream(prompt, attachments: attachments)) {
      yield chunk;
    }
    // After AI response completes, trigger analysis if user has sent >= 3 messages
    final userMessageCount = _provider.history.where((msg) => msg.origin.isUser).length;
    if (userMessageCount >= 2) {
      try {
        final analysisMsg = await AnalyzerService.instance.analyzeMessages(_provider.history.toList());
        // Append analysis message to provider history for display and storage
        _provider.history = [..._provider.history, analysisMsg];
        yield analysisMsg.text ?? '';
      } catch (e) {
        debugPrint('Analysis failed: $e');
      }
    }
  }

  @override
  void dispose() {
    // Remove listener before disposing controller
    _contextController.removeListener(_updateSystemPrompt);
    _provider.removeListener(_saveHistory);
    _contextController.dispose();
    // _analysisSubscription?.cancel(); // Cancel the Firestore listener - commented out
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
        appBar: AppBar(title: const Text(App.title)),
        // Use Column to arrange TextField and ChatView
        body: Column(
          children: [
            // Add Padding for scenario selection and context input
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column( // Use a Column for chips and text field
                crossAxisAlignment: CrossAxisAlignment.start, // Align items left
                children: [
                  // Use Wrap for scenario selection chips
                  const Text("Select a negotiation scenario:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0, // Horizontal space between chips
                    runSpacing: 4.0, // Vertical space between lines
                    children: predefinedScenarios.map((scenario) {
                      return ChoiceChip(
                        label: Text(scenario),
                        selected: _selectedScenario == scenario,
                        onSelected: (selected) {
                          setState(() {
                            // If selected is true, set the scenario, otherwise clear it (or handle deselection differently if needed)
                            _selectedScenario = selected ? scenario : null;
                            _updateSystemPrompt(); // Update prompt when scenario changes
                          });
                        },
                        // Optional styling
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: _selectedScenario == scenario
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                         shape: RoundedRectangleBorder( // Make chips more square
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: _selectedScenario == scenario
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16), // Spacing before conditional text field

                  // Conditionally display TextField for additional context
                  Visibility(
                    visible: _selectedScenario != null, // Show if any scenario is selected
                    child: TextField(
                      controller: _contextController,
                      decoration: const InputDecoration(
                        hintText: 'Enter additional context to refine the scenario (optional)...', // Changed hint text back
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
            // Add a divider
            const Divider(height: 1),
            // Make LlmChatView take remaining space
            Expanded(
              child: LlmChatView(
                provider: _provider, // Pass the initialized provider
                responseBuilder: _buildResponseWidget, // Pass the response builder
                messageSender: _messageSender, // Pass the custom message sender
              ),
            ),
          ],
        ),
      );

  Future<void> _saveHistory() async {
    debugPrint('_saveHistory called');
    
    // Get the latest history
    final history = _provider.history.toList();
    debugPrint('Saving: ${history.length} messages');

    // Use the storage abstraction to save history
    await _storage.saveHistory(history);
  }

  Future<void> _loadHistory() async {
    try {
      // Use the storage abstraction to load history
      final history = await _storage.loadHistory();
      
      if (history.isNotEmpty) {
        // Set the history on the provider
        _provider.history = history;
        debugPrint('Loaded ${history.length} messages from storage');
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }
} 