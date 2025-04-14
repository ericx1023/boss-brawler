import 'package:flutter/material.dart';

// A basic widget to display analysis feedback.
// TODO: Implement structured display (e.g., using Cards, ListTiles).
class AnalysisFeedbackView extends StatelessWidget {
  final String analysisContent;

  const AnalysisFeedbackView({super.key, required this.analysisContent});

  @override
  Widget build(BuildContext context) {
    // For now, just display the raw analysis content.
    // We will enhance this later to show structured feedback.
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Feedback:', // Title for the card
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(analysisContent), // Display the analysis content
          ],
        ),
      ),
    );
  }
} 