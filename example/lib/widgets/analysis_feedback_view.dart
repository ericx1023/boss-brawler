import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import Markdown

// A basic widget to display analysis feedback.
// TODO: Implement structured display (e.g., using Cards, ListTiles).
class AnalysisFeedbackView extends StatelessWidget {
  final String analysisContent;

  const AnalysisFeedbackView({super.key, required this.analysisContent});

  @override
  Widget build(BuildContext context) {
    // For now, just display the raw analysis content.
    // We will enhance this later to show structured feedback.
    return Container( // Use Container for full width and padding
      width: double.infinity,
      // Remove Card styling to avoid double-boxing if ChatHistoryView adds its own padding
      // color: Color(0xFF4A4B3A), // Dark olive-grey - remove if it's meant to be transparent against chat background
      margin: const EdgeInsets.symmetric(vertical: 4.0), // Keep some vertical margin
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding as needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Feedback:', // Title for the card
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Ensure title text is white
                ),
          ),
          const SizedBox(height: 8.0),
          MarkdownBody( // Use MarkdownBody to render content
            data: analysisContent,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white, // Ensure paragraph text is white
                  ),
              // You can add more specific styles here if needed for other markdown elements
              // For example, h1, h2, strong, em, etc.
              // strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              // em: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
              // listBullet: TextStyle(color: Colors.white),
              // blockquoteDecoration: BoxDecoration(color: Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(4)),
              // blockquotePadding: EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
} 