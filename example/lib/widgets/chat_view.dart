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
        // Customize user message bubbles
        userMessageStyle: UserMessageStyle(
          textStyle: TextStyle(color: Colors.black),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Customize LLM message bubbles
        llmMessageStyle: LlmMessageStyle(
          icon: Icons.smart_toy,
          iconColor: Colors.purple,
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Customize input field
        chatInputStyle: ChatInputStyle(
          backgroundColor: Colors.white,
          textStyle: TextStyle(fontSize: 16),
          hintText: 'Type your message...',
        ),
      ),

      responseBuilder: responseBuilder,
      messageSender: messageSender,
      afterUserMessageBuilder: afterUserMessageBuilder,
    );
  }
}
