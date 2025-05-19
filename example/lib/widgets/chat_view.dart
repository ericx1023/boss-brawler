import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

class ChatView extends StatelessWidget {
  final GeminiProvider provider;
  final Widget Function(BuildContext, String) responseBuilder;
  final Stream<String> Function(String, {Iterable<Attachment> attachments})
  messageSender;

  /// Builder to render a widget below the last user message in chat history.
  final Widget Function(BuildContext context, ChatMessage message)?
  afterUserMessageBuilder;

  const ChatView({
    Key? key,
    required this.provider,
    required this.responseBuilder,
    required this.messageSender,
    this.afterUserMessageBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LlmChatView(
      provider: provider,
      style: LlmChatViewStyle(
        // Attempt to set the overall background of the chat view area
        backgroundColor: Colors.black, // or Colors.transparent if black causes issues with other elements

        // Customize user message bubbles
        userMessageStyle: UserMessageStyle(
          textStyle: TextStyle(color: Colors.white),
          decoration: BoxDecoration(
            color: Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Customize LLM message bubbles
        llmMessageStyle: LlmMessageStyle(
          icon: Icons.smart_toy,
          iconColor: Colors.white70,
          decoration: BoxDecoration(
            color: Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Customize input field
        chatInputStyle: ChatInputStyle(
          backgroundColor: Color(0xFF3A3A3C),
          textStyle: TextStyle(color: Colors.white, fontSize: 16),
          hintText: 'Type something...',
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),

      responseBuilder: responseBuilder,
      messageSender: messageSender,
      afterUserMessageBuilder: afterUserMessageBuilder,
    );
  }
}
