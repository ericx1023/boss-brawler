// Manages prompt templates for the AI interaction.
class PromptManager {
  final Map<String, String> _templates = {
    // 'ai_opponent': """
    // Play a role of a tough negotiation opponent according to {{user_message}}.
    // Keep your responses concise and mean.
    // You will reply No, to reject the user, give a brief random reason.
    // User message: {{user_message}}
    // Opponent response:
    // """,
    // Add more templates here as needed
    'default': '{{user_message}}',
  };

  /// Formats a prompt using the specified template name and variables.
  ///
  /// Args:
  ///   templateName: The name of the template to use.
  ///   variables: A map of variable names (without curly braces) to their values.
  ///
  /// Returns:
  ///   The formatted prompt string, or null if the template is not found.
  String? formatPrompt(String templateName, Map<String, String> variables) {
    final template = _templates[templateName];
    if (template == null) {
      print('Error: Template "$templateName" not found.');
      return null;
    }

    String formattedPrompt = template;
    variables.forEach((key, value) {
      formattedPrompt = formattedPrompt.replaceAll('{{$key}}', value);
    });

    return formattedPrompt;
  }

  /// Gets a basic prompt using the user message directly.
  String getBasicPrompt(String userMessage) {
    // Or use formatPrompt('default', {'user_message': userMessage});
    return userMessage;
  }

  // /// Gets the AI coach prompt formatted with the user message.
  // String? getCoachPrompt(String userMessage) {
  //   return formatPrompt('ai_opponent', {'user_message': userMessage});
  // }
} 