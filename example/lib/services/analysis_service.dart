import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'analyzer_service.dart';

/// Wrapper service for performing analysis on chat history
class AnalysisService {
  final AnalyzerService _analyzer = AnalyzerService.instance;

  /// Analyze chat history and return an analysis message
  Future<ChatMessage> analyzeMessages(List<ChatMessage> history) {
    return _analyzer.analyzeMessages(history);
  }
} 