import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
admin.initializeApp(); // Initialize Firebase Admin SDK
// TODO: Initialize Firebase Admin SDK if not already done
// admin.initializeApp();

/**
 * Analyzes a user's negotiation message using an AI model.
 *
 * @param {object} data - The data passed to the function.
 * @param {string} data.message - The user message to analyze.
 * @param {string} data.conversationId - The ID of the conversation.
 * @param {object} context - The context object containing auth information.
 * @returns {Promise<object>} - A promise that resolves with the analysis
 *                           result.
 */
exports.analyzeNegotiationMessage = functions.https
  .onCall(async (data: any, context: any) => {
    // TODO: Add authentication check if required
    // if (!context.auth) {
    //   throw new functions.https.HttpsError(
    //     "unauthenticated",
    //     "The function must be called while authenticated.");
    // }

    const {message, conversationId} = data;

    if (!message || !conversationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with arguments " +
        "'message' and 'conversationId'.",
      );
    }

    functions.logger.info(
      `Received request to analyze message for conversation ${conversationId}`,
      {structuredData: true},
    );

    try {
      // --- 1. Trigger Logic ---
      // TODO: Implement logic to decide if analysis should proceed
      // e.g., check message count in conversation, explicit user request, etc.
      // For now, we'll proceed directly.
      const shouldAnalyze = true;

      if (!shouldAnalyze) {
        functions.logger.info(
          `Skipping analysis for conversation ${conversationId}`,
          {structuredData: true},
        );
        return {status: "skipped", reason: "Trigger condition not met"};
      }

      // --- 2. Fetch Prompt ---
      // TODO: Load the prompt template
      // (e.g., from Firestore config or a file)
      // Splitting the long prompt string
      // into multiple lines using template literals
      const promptTemplate = `
Analyze the following negotiation message based on Clarity, Assertiveness,
Flexibility, and Empathy metrics (scale 1-5).
Provide a score for each metric and brief constructive feedback for improvement.

User Message:
"{user_message}"

Analysis Output Format (JSON):
{
  "scores": {
    "clarity": <score>,
    "assertiveness": <score>,
    "flexibility": <score>,
    "empathy": <score>
  },
  "feedback": {
    "overall": "<Overall constructive feedback>",
    "clarity": "<Specific feedback on clarity>",
    "assertiveness": "<Specific feedback on assertiveness>",
    "flexibility": "<Specific feedback on flexibility>",
    "empathy": "<Specific feedback on empathy>"
  }
}
`; // Placeholder
      const filledPrompt = promptTemplate.replace("{user_message}", message);

      // --- 3. Call AI Service ---
      // TODO: Replace with actual call to the AI service
      // (e.g., Vertex AI, OpenAI)
      functions.logger.info(
        `Calling AI service for conversation ${conversationId}`,
        {structuredData: true},
      );
      // const aiResponse = await callAIService(filledPrompt);
      // Mock response for now:
      const mockAiResponse = {
        scores: {
          clarity: 4,
          assertiveness: 3,
          flexibility: 5,
          empathy: 4,
        },
        feedback: {
          overall: "Good progress, focus on being slightly more assertive.",
          clarity: "Message is clear.",
          assertiveness:
            "Consider stating your minimum acceptable point more directly.",
          flexibility: "Excellent flexibility shown.",
          empathy: "Good acknowledgement of the other party's view.",
        },
      };
      // Simulate API call delay
      await new Promise((resolve) => setTimeout(resolve, 500));
      const analysisResult = mockAiResponse; // Assume parsing is done if needed

      // --- 4. Process & Format Results ---
      // TODO: Add any additional processing or validation if needed
      const structuredResult = {
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        messageAnalyzed: message,
        ...analysisResult,
      };

      // --- 5. Store Results (Covered in Subtask 4.3) ---
      // TODO: Implement logic to save structuredResult to Firestore
      const analysisCollectionRef = admin.firestore()
        .collection("conversations").doc(conversationId)
        .collection("analysis");
      await analysisCollectionRef.add(structuredResult);
      functions.logger.info(
        `Analysis successful for conversation ${conversationId}`,
        {structuredData: true},
      );

      // --- 6. Return Results ---
      // The function returns the result,
      // the client-side will handle integration
      return {status: "success", analysis: structuredResult};
    } catch (error) {
      functions.logger.error(
        `Error analyzing message for conversation ${conversationId}:`,
        error,
      );
      // TODO: Implement more specific error handling
      throw new functions.https.HttpsError(
        "internal",
        "Failed to analyze message.",
        (error as Error).message,
      );
    }
  });

// TODO: Add helper function for calling the actual AI service
// async function callAIService(prompt) { ... } 