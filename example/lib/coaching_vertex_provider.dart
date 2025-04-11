import 'dart:async'; // Import async for Timer

import 'package:firebase_core/firebase_core.dart'; // Import for FirebaseException
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter/foundation.dart';
import 'package:retry/retry.dart'; // Import retry package
import 'dart:developer' as developer; // Import developer for logging

import 'prompt_manager.dart';

/// An AiProvider that uses a PromptManager to format prompts for a Vertex AI model,
/// specifically designed for the AI coaching scenario.
class CoachingVertexProvider with ChangeNotifier implements LlmProvider {
  final GenerativeModel model;
  final PromptManager promptManager;
  bool _isGenerating = false;
  final List<ChatMessage> _history = [];

  // Configure retry options
  final _retryOptions = const RetryOptions(
    maxAttempts: 3, // Try 3 times before failing
    delayFactor: Duration(milliseconds: 200), // Wait 200ms, 400ms, 800ms
    maxDelay: Duration(seconds: 2), // Max delay of 2 seconds
  );

  CoachingVertexProvider({required this.model, required this.promptManager});

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    _isGenerating = true;
    notifyListeners();

    final userMessage = ChatMessage(origin: MessageOrigin.user, text: prompt, attachments: attachments);
    _history.add(userMessage);
    // Notify after adding potential error message or success message

    // Reference to potentially add error message later
    ChatMessage? errorMessage;

    try {
      // TODO: Enhance prompt formatting (remains unchanged)
      // ... (existing prompt formatting logic) ...

      final content = [Content.text(prompt)];

      // Use retry mechanism for the API call
      final responseStream = await _retryOptions.retry<Stream<GenerateContentResponse>>(
        () => model.generateContentStream(content),
        retryIf: (e) => _shouldRetry(e), // Define which errors should trigger a retry
        onRetry: (e) => developer.log('Retrying API call after error: $e', name: 'CoachingVertexProvider'),
      );

      String fullResponse = '';
      await for (final chunk in responseStream) {
        // Check for safety ratings or other non-text parts if needed
        // final safety = chunk.candidates.first.safetyRatings;
        // if (safety != null && safety.any((r) => r.probability != HarmProbability.negligible)) {
        //   developer.log('Content blocked due to safety ratings: ${safety.map((r) => '${r.category}: ${r.probability}')}', name: 'CoachingVertexProvider');
        //   yield 'Error: Content blocked due to safety concerns.';
        //   errorMessage = ChatMessage(origin: MessageOrigin.llm, text: 'Error: Content blocked due to safety concerns.', attachments: []); // Use llm, add attachments
        //   // Stop processing this response stream
        //   return;
        // }

        final text = chunk.text;
        if (text != null) {
          fullResponse += text;
          yield text;
        } else {
           developer.log('Received chunk with no text: ${chunk.candidates.firstOrNull?.finishReason}', name: 'CoachingVertexProvider');
           // Handle potential finish reasons if necessary
        }
      }

       if (fullResponse.isEmpty && errorMessage == null) { // Check if errorMessage already set (e.g., by safety block)
         // Handle cases where the stream completed but yielded no text
         developer.log('API call succeeded but returned empty response.', name: 'CoachingVertexProvider');
         const emptyResponseError = 'AI returned an empty response.';
         errorMessage = ChatMessage(origin: MessageOrigin.llm, text: emptyResponseError, attachments: []); // Use llm, add attachments
         yield 'Error: $emptyResponseError';
       } else if (errorMessage == null) { // Only add successful LLM response if no error occurred
         final llmMessage = ChatMessage(origin: MessageOrigin.llm, text: fullResponse, attachments: []);
         _history.add(llmMessage);
       }


    } on FirebaseException catch (e) {
      developer.log('FirebaseException calling Vertex AI: ${e.code} - ${e.message}', name: 'CoachingVertexProvider', error: e, stackTrace: e.stackTrace);
      final userFacingError = _mapFirebaseError(e);
      errorMessage = ChatMessage(origin: MessageOrigin.llm, text: userFacingError, attachments: []); // Use llm, add attachments
      yield userFacingError;
    } catch (e, stackTrace) {
      developer.log('Generic error calling Vertex AI: $e', name: 'CoachingVertexProvider', error: e, stackTrace: stackTrace);
      const userFacingError = 'An unexpected error occurred while contacting the AI.';
      errorMessage = ChatMessage(origin: MessageOrigin.llm, text: userFacingError, attachments: []); // Use llm, add attachments
      yield userFacingError;
    } finally {
      _isGenerating = false;
      if (errorMessage != null) {
        _history.add(errorMessage); // Add the error message to history
      }
      notifyListeners(); // Notify state and history changes
    }
  }

  // Helper function to determine if an error should be retried
  bool _shouldRetry(Exception e) {
    if (e is FirebaseException) {
      // Example: Retry on transient network errors or rate limits
      // Adjust codes based on actual Vertex AI/Firebase error codes
      return e.code == 'unavailable' || e.code == 'resource-exhausted' || e.code == 'internal';
    }
    // Optionally retry on other transient error types like TimeoutException
    if (e is TimeoutException) {
      return true;
    }
    return false; // Default to not retrying unknown errors
  }

  // Helper function to map Firebase errors to user-friendly messages
  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'The AI service is temporarily unavailable. Please try again later.';
      case 'resource-exhausted':
        return 'The AI service is currently busy. Please try again shortly.';
      case 'permission-denied':
        return 'Error: Permission denied. Check API key or configuration.';
      case 'invalid-argument':
         return 'Error: Invalid request sent to AI. Check prompt content.';
      // Add more specific mappings as needed
      default:
        return 'An error occurred while communicating with the AI (${e.code}).';
    }
  }

  @override
  bool get isGenerating => _isGenerating;

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
  }) async* {
     // This stream does not interact with history
     // Implement similar retry and error handling as sendMessageStream
     try {
        // TODO: Prompt formatting if needed
        final content = [Content.text(prompt)]; // Assuming generateStream doesn't use attachments here

        // Use retry mechanism
        final responseStream = await _retryOptions.retry<Stream<GenerateContentResponse>>(
          () => model.generateContentStream(content),
          retryIf: (e) => _shouldRetry(e),
          onRetry: (e) => developer.log('Retrying generateStream API call after error: $e', name: 'CoachingVertexProvider'),
        );

        bool yieldedData = false;
        await for (final chunk in responseStream) {
           // Add safety check similar to sendMessageStream if needed
           final text = chunk.text;
           if (text != null) {
              yieldedData = true;
              yield text;
           } else {
              developer.log('generateStream received chunk with no text: ${chunk.candidates.firstOrNull?.finishReason}', name: 'CoachingVertexProvider');
           }
        }

        if (!yieldedData) {
          developer.log('generateStream succeeded but returned empty response.', name: 'CoachingVertexProvider');
          yield 'Error: AI returned an empty response.'; // Yield error string
        }

     } on FirebaseException catch (e) {
       developer.log('FirebaseException in generateStream: ${e.code} - ${e.message}', name: 'CoachingVertexProvider', error: e, stackTrace: e.stackTrace);
       yield _mapFirebaseError(e); // Return user-friendly error string
     } catch (e, stackTrace) {
       developer.log('Generic error in generateStream: $e', name: 'CoachingVertexProvider', error: e, stackTrace: stackTrace);
       yield 'An unexpected error occurred.'; // Generic fallback string
     }
     // No finally block needed here as it doesn't manage _isGenerating or history
  }

  // dispose, addListener, removeListener, hasListeners are inherited from ChangeNotifier
} 