import 'package:firebase_vertexai/firebase_vertexai.dart';

/// Abstract interface to wrap the GenerativeModel for easier mocking.
abstract class VertexAiModelAdapter {
  /// Wraps the GenerativeModel.generateContentStream method.
  Stream<GenerateContentResponse> generateContentStream(Iterable<Content> content);
}

/// Concrete implementation of the adapter that uses the actual GenerativeModel.
class GenerativeModelAdapter implements VertexAiModelAdapter {
  final GenerativeModel _model;

  GenerativeModelAdapter(this._model);

  @override
  Stream<GenerateContentResponse> generateContentStream(Iterable<Content> content) {
    return _model.generateContentStream(content);
  }
} 