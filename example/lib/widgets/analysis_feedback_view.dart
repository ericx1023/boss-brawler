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
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Color(0xFF4A4B3A), // Dark olive-grey
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Optional: match bubble radius
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
              Text(
                analysisContent, // Display the analysis content
                style: TextStyle(color: Colors.white), // Ensure content text is white
              ),
            ],
          ),
        ),
      ),
    );
  }
} 