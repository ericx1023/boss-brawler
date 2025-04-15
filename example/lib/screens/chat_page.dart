import 'dart:async'; // Import async for StreamSubscription

import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import flutter_markdown
import 'package:cloud_functions/cloud_functions.dart'; // Import Cloud Functions
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:uuid/uuid.dart'; // Import Uuid

import '../main.dart'; // For App.title
import '../../gemini_api_key.dart'; // Adjusted path for api key
import '../widgets/analysis_feedback_view.dart'; // Import the new widget

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
  // State variable for the selected scenario
  String? _selectedScenario; // Nullable string for selected scenario

  // Add state variables for Firestore, Functions, Conversation ID, and Provider
  late final String _conversationId;
  late final FirebaseFirestore _firestore;
  late final FirebaseFunctions _functions;
  late GeminiProvider _provider; // Make provider mutable
  StreamSubscription? _analysisSubscription;
  Timestamp? _lastAnalysisTimestamp; // Keep track of the last displayed analysis

  @override
  void initState() {
    super.initState();
    _currentSystemPrompt = negotiationCoachSystemPrompt;

    // Initialize ID, Firestore, Functions
    _conversationId = const Uuid().v4();
    _firestore = FirebaseFirestore.instance;
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1'); // Match function region

    // Initial provider creation and system prompt update
    _updateSystemPrompt();

    // Add listener *after* initial update
    _contextController.addListener(_updateSystemPrompt);

    // Start listening for analysis results
    _listenForAnalysis();
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

      // Recreate the provider with the new system instruction
      _provider = GeminiProvider(
        model: GenerativeModel(
          model: 'gemini-2.0-flash', // Or your preferred model
          apiKey: geminiApiKey,
          systemInstruction: Content.system(_currentSystemPrompt), // Use the constructed prompt
        ),
      );
      // Optional: Print the prompt for debugging
      // debugPrint("Updated System Prompt:\n$_currentSystemPrompt");
    });
  }

  // --- Cloud Function Trigger ---
  Future<void> _triggerAnalysis(String userMessage) async {
    // Avoid triggering analysis for empty messages or analysis results themselves
    if (userMessage.isEmpty || userMessage.startsWith('[ANALYSIS]:')) return;
    debugPrint('Triggering analysis for message: $userMessage');
    try {
      // Ensure the conversation document exists before calling the function
      // This prevents errors if the function tries to update a non-existent doc
      // Alternatively, the function itself could handle document creation/check.
      await _firestore.collection('conversations').doc(_conversationId).set({}, SetOptions(merge: true));

      final callable = _functions.httpsCallable('analyzeNegotiationMessage');
      await callable.call(<String, dynamic>{
        'message': userMessage,
        'conversationId': _conversationId,
      });
      debugPrint('Analysis function called successfully.');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Error calling analysis function: ${e.code} - ${e.message}');
      // Optionally show an error message to the user
    } catch (e) {
      debugPrint('Unexpected error calling analysis function: $e');
    }
  }

  // --- Firestore Listener ---
  void _listenForAnalysis() {
    _analysisSubscription = _firestore
        .collection('conversations')
        .doc(_conversationId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final feedback = data['latestAnalysisFeedback'] as String?;
        final timestamp = data['lastAnalysisTimestamp'] as Timestamp?;

        // Check if feedback exists and is newer than the last one shown
        if (feedback != null && feedback.isNotEmpty && timestamp != null &&
            (_lastAnalysisTimestamp == null || timestamp.compareTo(_lastAnalysisTimestamp!) > 0))
         {
          debugPrint('New analysis feedback received: $feedback');

          // Create a ChatMessage for the analysis feedback
          final analysisMessage = ChatMessage(
              origin: MessageOrigin.llm, // Display as if it's from the AI
              text: feedback, // The text starts with [ANALYSIS]:
              attachments: const [], // No attachments for analysis
              // Optionally add metadata if ChatMessage supports it
              );

          // Add the message to the provider's history
          // Ensure this modification triggers a UI update (ListenableProvider should handle this)
          // Avoid adding if the exact same message text is already the last one
           if (_provider.history.isEmpty || _provider.history.last.text != analysisMessage.text) {
             _provider.history = [..._provider.history, analysisMessage];
             // Update the state to store the timestamp of the last added analysis
             // This ensures we don't re-add the same analysis on rebuilds/hot reloads
             _lastAnalysisTimestamp = timestamp;
             // No need to call setState if provider notifies listeners, which it should
             // If UI doesn't update, uncomment the setState below
             // setState(() {});
           }
        }
      } else {
         debugPrint("Conversation document ${_conversationId} does not exist yet.");
      }
    }, onError: (error) {
      debugPrint('Error listening to analysis feedback: $error');
    });
  }

  // --- Custom Message Sender ---
  Stream<String> _messageSender(String prompt, {Iterable<Attachment> attachments = const []}) {
    // Trigger analysis BEFORE sending the message to the regular AI
    // Use Future.delayed to ensure it doesn't block the message stream start
    Future.delayed(Duration.zero, () => _triggerAnalysis(prompt));

    // Call the original provider's method to get the AI's conversational response
    return _provider.sendMessageStream(prompt, attachments: attachments);
  }

  @override
  void dispose() {
    // Remove listener before disposing controller
    _contextController.removeListener(_updateSystemPrompt);
    _contextController.dispose();
    _analysisSubscription?.cancel(); // Cancel the Firestore listener
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
} 