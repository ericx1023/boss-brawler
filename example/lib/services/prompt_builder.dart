import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

class PromptBuilder {
  final String defaultPrompt;

  PromptBuilder({required this.defaultPrompt});

  /// Builds the full system prompt using optional scenario and user context.
  String buildPrompt({String? scenario, String? context}) {
    final buffer = StringBuffer(defaultPrompt);
    if ((scenario != null && scenario.isNotEmpty) || (context != null && context.isNotEmpty)) {
      buffer.write("\n\n");
      if (scenario != null && scenario.isNotEmpty) {
        buffer.writeln("Selected Scenario: $scenario");
        if (context != null && context.isNotEmpty) buffer.write("\n");
      }
      // if (context != null && context.isNotEmpty) {
      //   buffer.writeln("Additional Context Provided by User:\n$context");
      // }
    }
    return buffer.toString().trim();
  }
} 