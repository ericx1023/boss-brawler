import 'package:cross_file/cross_file.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'ai_config.dart';

/// Service for speech-to-text functionality
class SttService {
  late final GeminiProvider _sttProvider;
  
  SttService() {
    _sttProvider = GeminiProvider(
      model: AiConfig.createSttModel(),
    );
  }

  /// Translate audio file to text
  Stream<String> translateAudio(XFile file) async* {
    const prompt =
        'translate the attached audio to text; provide the result of that '
        'translation as just the text of the translation itself. be careful to '
        'separate the background audio from the foreground audio and only '
        'provide the result of translating the foreground audio.';
    
    final attachments = [await FileAttachment.fromFile(file)];
    
    yield* _sttProvider.generateStream(
      prompt,
      attachments: attachments,
    );
  }

  /// Dispose resources
  void dispose() {
    // Provider doesn't need explicit disposal
  }
} 