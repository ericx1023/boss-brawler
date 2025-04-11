import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart'; // For ChatMessage, LlmProvider
import 'package:flutter_ai_toolkit_example/coaching_vertex_provider.dart';
import 'package:flutter_ai_toolkit_example/prompt_manager.dart'; // Import PromptManager
import 'package:flutter_ai_toolkit_example/vertex_ai_model_adapter.dart'; // Import the adapter

import 'coaching_vertex_provider_test.mocks.dart'; // Import generated mocks

// Annotate classes to be mocked
// @GenerateMocks([GenerativeModel, PromptManager]) // Mock the adapter instead
@GenerateMocks([VertexAiModelAdapter, PromptManager])
void main() {
  // Test setup will go here
  // late MockGenerativeModel mockModel; // Remove original model mock
  late MockVertexAiModelAdapter mockModelAdapter; // Mock the adapter
  late MockPromptManager mockPromptManager;
  late CoachingVertexProvider provider;

  setUp(() {
    // Initialize mocks before each test
    // mockModel = MockGenerativeModel(); // Remove
    mockModelAdapter = MockVertexAiModelAdapter(); // Initialize adapter mock
    mockPromptManager = MockPromptManager();
    provider = CoachingVertexProvider(
      // model: mockModel, // Remove
      modelAdapter: mockModelAdapter, // Inject adapter mock
      promptManager: mockPromptManager,
    );
  });

  // Helper function to create a GenerateContentResponse for mocking
  GenerateContentResponse _createResponse({String? text, FinishReason? finishReason = FinishReason.stop}) {
    final content = Content('model', [TextPart(text ?? '')]);
    final candidate = Candidate(
      content,       // 1. content
      null,          // 2. safetyRatings
      null,          // 3. citationMetadata
      finishReason,  // 4. finishReason
      null,          // 5. finishMessage
      // functionCalls and index seem to be optional or handled differently
    );
    return GenerateContentResponse(
      [candidate], // 1. candidates
      null,       // 2. promptFeedback
      // usageMetadata seems optional or handled differently
    );
  }

  group('CoachingVertexProvider Tests', () {
    // Individual tests will go here
    testWidgets('sendMessageStream success updates history and state', (WidgetTester tester) async {
      // Arrange: Mock the API response stream using the helper
      final responseChunk1 = _createResponse(text: 'Hello ');
      final responseChunk2 = _createResponse(text: 'there!');
      final responseStream = Stream.fromIterable([responseChunk1, responseChunk2]);

      when(mockModelAdapter.generateContentStream(any)) // Mock adapter method
          .thenAnswer((_) => responseStream);

      // Act: Call the method
      final List<String> receivedChunks = [];
      final List<bool> generatingStates = [];
      final List<List<ChatMessage>> historyStates = [];

      // Listen to provider changes
      provider.addListener(() {
        generatingStates.add(provider.isGenerating);
        // Create a copy of history to capture the state at this point
        historyStates.add(List.from(provider.history));
      });

      final resultStream = provider.sendMessageStream('Hi');
      await for (final chunk in resultStream) {
        receivedChunks.add(chunk);
      }

      // Assert
      expect(receivedChunks, ['Hello ', 'there!']);

      // Check isGenerating states: true (start), false (end)
      expect(generatingStates, [true, false]);

      // Check history states:
      // 1. User message added (before API call starts yielding, listener might fire early)
      // 2. LLM message added after stream completion
      expect(historyStates.length, greaterThanOrEqualTo(1)); // At least the final state change

      final finalHistory = historyStates.last;
      expect(finalHistory.length, 2); // User message + LLM message
      expect(finalHistory[0].origin, MessageOrigin.user);
      expect(finalHistory[0].text, 'Hi');
      expect(finalHistory[1].origin, MessageOrigin.llm);
      expect(finalHistory[1].text, 'Hello there!');

      // Final state check
      expect(provider.isGenerating, false);
      expect(provider.history.length, 2);
    });

    testWidgets('sendMessageStream handles FirebaseException and updates history', (WidgetTester tester) async {
      // Arrange: Mock the API call to throw a specific FirebaseException
      final exception = FirebaseException(
        plugin: 'vertexai',
        code: 'permission-denied',
        message: 'Permission denied',
      );
      // when(mockModel.generateContentStream(any)).thenThrow(exception);
      when(mockModelAdapter.generateContentStream(any)).thenThrow(exception); // Mock adapter method

      // Act: Call the method and collect results/errors
      final List<String> receivedChunks = [];
      final List<bool> generatingStates = [];
      final List<List<ChatMessage>> historyStates = [];
      String? errorChunk;

       provider.addListener(() {
        generatingStates.add(provider.isGenerating);
        historyStates.add(List.from(provider.history));
      });

      final resultStream = provider.sendMessageStream('Test Error');
      await for (final chunk in resultStream) {
         // The provider yields the error message as the last chunk
         errorChunk = chunk;
         receivedChunks.add(chunk);
      }


      // Assert
      expect(receivedChunks.length, 1); // Should only yield the error message
      expect(errorChunk, contains('Error: Permission denied'));

      // Check isGenerating states: true (start), false (end)
      expect(generatingStates, [true, false]);

      // Check history: User message + System/LLM error message
      final finalHistory = historyStates.last;
      expect(finalHistory.length, 2);
      expect(finalHistory[0].origin, MessageOrigin.user);
      expect(finalHistory[0].text, 'Test Error');
      expect(finalHistory[1].origin, MessageOrigin.llm); // Error messages use llm origin
      expect(finalHistory[1].text, contains('Error: Permission denied'));

       // Final state check
      expect(provider.isGenerating, false);
      expect(provider.history.length, 2);
    });

     testWidgets('sendMessageStream handles generic exception and updates history', (WidgetTester tester) async {
      // Arrange: Mock the API call to throw a generic exception
      final exception = Exception('Something went wrong');
      // when(mockModel.generateContentStream(any)).thenThrow(exception);
      when(mockModelAdapter.generateContentStream(any)).thenThrow(exception); // Mock adapter method

      // Act: Call the method and collect results/errors
      final List<String> receivedChunks = [];
      final List<bool> generatingStates = [];
      final List<List<ChatMessage>> historyStates = [];
      String? errorChunk;

       provider.addListener(() {
        generatingStates.add(provider.isGenerating);
        historyStates.add(List.from(provider.history));
      });

      final resultStream = provider.sendMessageStream('Generic Error Test');
       await for (final chunk in resultStream) {
         errorChunk = chunk;
         receivedChunks.add(chunk);
       }

      // Assert
      expect(receivedChunks.length, 1);
      expect(errorChunk, 'An unexpected error occurred while contacting the AI.');

      // Check isGenerating states: true (start), false (end)
      expect(generatingStates, [true, false]);

       // Check history: User message + System/LLM error message
      final finalHistory = historyStates.last;
      expect(finalHistory.length, 2);
      expect(finalHistory[0].origin, MessageOrigin.user);
      expect(finalHistory[0].text, 'Generic Error Test');
      expect(finalHistory[1].origin, MessageOrigin.llm);
      expect(finalHistory[1].text, 'An unexpected error occurred while contacting the AI.');

       // Final state check
      expect(provider.isGenerating, false);
      expect(provider.history.length, 2);
    });

    testWidgets('sendMessageStream handles empty API response and updates history', (WidgetTester tester) async {
      // Arrange: Mock an empty stream response
      final responseStream = Stream<GenerateContentResponse>.empty();
      // when(mockModel.generateContentStream(any))
      when(mockModelAdapter.generateContentStream(any)) // Mock adapter method
          .thenAnswer((_) => responseStream);

       // Act
       final List<String> receivedChunks = [];
       final List<bool> generatingStates = [];
       final List<List<ChatMessage>> historyStates = [];
       String? errorChunk;

       provider.addListener(() {
         generatingStates.add(provider.isGenerating);
         historyStates.add(List.from(provider.history));
       });

       final resultStream = provider.sendMessageStream('Empty Test');
       await for (final chunk in resultStream) {
         errorChunk = chunk;
         receivedChunks.add(chunk);
       }

       // Assert
       expect(receivedChunks.length, 1); // Should yield the "empty response" error
       expect(errorChunk, 'Error: AI returned an empty response.');

       expect(generatingStates, [true, false]);

       final finalHistory = historyStates.last;
       expect(finalHistory.length, 2); // User msg + Error msg
       expect(finalHistory[0].text, 'Empty Test');
       expect(finalHistory[1].origin, MessageOrigin.llm);
       expect(finalHistory[1].text, 'AI returned an empty response.');

       expect(provider.isGenerating, false);
    });


    testWidgets('generateStream success yields chunks', (WidgetTester tester) async {
       // Arrange using the helper
       final responseChunk1 = _createResponse(text: 'Generated ');
       final responseChunk2 = _createResponse(text: 'content.');
       final responseStream = Stream.fromIterable([responseChunk1, responseChunk2]);

       when(mockModelAdapter.generateContentStream(any)) // Mock adapter method
           .thenAnswer((_) => responseStream);

       // Act
       final List<String> receivedChunks = [];
       final resultStream = provider.generateStream('Generate something');
       await for (final chunk in resultStream) {
         receivedChunks.add(chunk);
       }

       // Assert
       expect(receivedChunks, ['Generated ', 'content.']);
       // Verify generateStream does not modify history or isGenerating state
       expect(provider.isGenerating, false);
       expect(provider.history.isEmpty, true);
    });

     testWidgets('generateStream handles errors', (WidgetTester tester) async {
       // Arrange
        final exception = FirebaseException(plugin: 'vertexai', code: 'unavailable');
        // when(mockModel.generateContentStream(any)).thenThrow(exception);
        when(mockModelAdapter.generateContentStream(any)).thenThrow(exception); // Mock adapter method

       // Act
       final List<String> receivedChunks = [];
       String? errorChunk;
       // Use tester.runAsync to handle async operations including delays from retry
       await tester.runAsync(() async {
         final resultStream = provider.generateStream('Generate error test');
          await for (final chunk in resultStream) {
            errorChunk = chunk;
            receivedChunks.add(chunk);
          }
       });

       // Assert
       expect(receivedChunks.length, 1);
       expect(errorChunk, contains('The AI service is temporarily unavailable'));
       expect(provider.isGenerating, false);
       expect(provider.history.isEmpty, true);
    });

     testWidgets('history setter updates history and notifies listeners', (WidgetTester tester) async {
        // Arrange
        final initialHistory = [ChatMessage(origin: MessageOrigin.user, text: 'Initial', attachments: [])];
        final newHistory = [
          ChatMessage(origin: MessageOrigin.user, text: 'New 1', attachments: []),
          ChatMessage(origin: MessageOrigin.llm, text: 'New 2', attachments: [])
        ];
        provider.history = initialHistory; // Set initial state

        bool notified = false;
        provider.addListener(() {
          notified = true;
        });

        // Act
        provider.history = newHistory;

        // Assert
        expect(provider.history, orderedEquals(newHistory));
        expect(notified, true); // Verify listener was called
     });

  });
}

// Remove the old MockGenerateContentResponse and related mock classes
// class MockGenerateContentResponse implements GenerateContentResponse { ... }
// class MockCandidate implements Candidate { ... }
// class MockContent implements Content { ... }
// class MockTextPart implements TextPart { ... } 