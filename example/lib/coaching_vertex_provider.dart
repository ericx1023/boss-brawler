import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter/foundation.dart';

import 'prompt_manager.dart';

/// An AiProvider that uses a PromptManager to format prompts for a Vertex AI model,
/// specifically designed for the AI coaching scenario.
class CoachingVertexProvider with ChangeNotifier implements LlmProvider {
  final GenerativeModel model;
  final PromptManager promptManager;
  bool _isGenerating = false;
  final List<ChatMessage> _history = [];

  CoachingVertexProvider({required this.model, required this.promptManager});

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* { // Match LlmProvider signature
    _isGenerating = true;
    notifyListeners();

    // Create user message and add to history
    final userMessage = ChatMessage(origin: MessageOrigin.user, text: prompt, attachments: attachments);
    _history.add(userMessage);
    // Don't notify yet, wait for LLM response addition

    try {
      // Format the prompt using the coach template (using the direct prompt)
      // TODO: Enhance prompt formatting to include relevant history if needed
      // final formattedPrompt = promptManager.getCoachPrompt(prompt);

      // if (formattedPrompt == null) {
      //   yield 'Error: Could not format prompt.';
      //   // Decide if an error message should be added to history here or handled differently
      //   _isGenerating = false;
      //   notifyListeners(); // Notify state change even on format error
      //   return;
      // }

      // Prepare content for the model - System prompt is handled by model initialization
      final content = [
          // Add history if needed:
          // ...history?.map((msg) => msg.toContent()).toList() ?? [],
          Content.text(prompt) // Only send the user's current message
        ]; // Or Content('user', [TextPart(formattedPrompt), ...attachments.map(...)]) if attachments needed here

      // Call the Vertex AI model and stream the response
      final responseStream = model.generateContentStream(content);

      String fullResponse = '';
      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null) {
          fullResponse += text;
          yield text;
        }
      }

      // Create LLM response message and add to history
      final llmMessage = ChatMessage(origin: MessageOrigin.llm, text: fullResponse, attachments: []);
      _history.add(llmMessage);
      notifyListeners(); // Notify history and state change after LLM response

    } catch (e) {
      print('Error calling Vertex AI: $e');
      yield 'Error: Could not get response from AI.';
      // No system message added to history
    } finally {
      _isGenerating = false;
      // Notify state change, history notification happened in try block on success
      if (hasListeners) { // Check if listeners exist before notifying
           notifyListeners();
      }
    }
  }

  @override
  bool get isGenerating => _isGenerating;

  // Removed the non-interface sendMessage method

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> newHistory) {
    _history.clear();
    _history.addAll(newHistory);
    notifyListeners();
  }

  @override
  Stream<String> generateStream(
      String prompt, {
      Iterable<Attachment> attachments = const [],
  }) async* { // Match LlmProvider signature
     // This stream does not interact with history
     try {
        // Format prompt (without history context)
        // final formattedPrompt = promptManager.getCoachPrompt(prompt);

        // if (formattedPrompt == null) {
        //   yield 'Error: Could not format prompt.';
        //   return;
        // }

        // Prepare content - consider if attachments are needed for generateStream
        final content = [
            // Add history if needed:
            // ...history?.map((msg) => msg.toContent()).toList() ?? [],
            Content.text(prompt) // Only send the user's current message
          ]; // Or include attachments if needed

        final responseStream = model.generateContentStream(content);

        await for (final chunk in responseStream) {
           final text = chunk.text;
           if (text != null) {
              yield text;
           }
        }
     } catch (e) {
        print('Error in generateStream: $e');
        yield 'Error: Could not generate response.';
     }
  }

  // dispose, addListener, removeListener, hasListeners are inherited from ChangeNotifier
} 