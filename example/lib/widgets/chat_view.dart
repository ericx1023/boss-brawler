import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

class ChatView extends StatelessWidget {
  final GeminiProvider provider;
  final Widget Function(BuildContext, String) responseBuilder;
  final Stream<String> Function(String, {Iterable<Attachment> attachments}) messageSender;

  const ChatView({
    Key? key,
    required this.provider,
    required this.responseBuilder,
    required this.messageSender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LlmChatView(
      provider: provider,
      responseBuilder: responseBuilder,
      messageSender: messageSender,
    );
  }
} 