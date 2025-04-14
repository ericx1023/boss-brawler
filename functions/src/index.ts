import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as fs from "fs"; // Import fs for file reading
import * as path from "path"; // Import path for resolving file paths

// Import Vertex AI library
import {VertexAI} from "@google-cloud/vertexai";

admin.initializeApp(); // Initialize Firebase Admin SDK

// Initialize Vertex AI client
// Ensure GCLOUD_PROJECT and GCLOUD_LOCATION are set in your environment
const project = process.env.GCLOUD_PROJECT || functions.config().project?.id;
const location = process.env.GCLOUD_LOCATION || "us-central1"; // Default location, change if needed

if (!project) {
  console.error("GCLOUD_PROJECT environment variable not set.");
  // Handle the error appropriately, maybe throw or exit
}

const vertexAI = new VertexAI({project: project, location: location});
const generativeModel = vertexAI.getGenerativeModel({
  // Specify the Gemini model to use
  model: "gemini-1.5-flash", // Or your preferred model
});

// --- Helper function to call the AI service ---
/**
 * Calls the Vertex AI Gemini model to get analysis.
 * @param {string} prompt The complete prompt to send to the model.
 * @return {Promise<string>} The raw text response from the model.
 */
async function callAIService(prompt: string): Promise<string> {
  try {
    const request = {
      contents: [{role: "user", parts: [{text: prompt}]}],
    };
    const resp = await generativeModel.generateContent(request);

    if (
      !resp.response ||
      !resp.response.candidates ||
      resp.response.candidates.length === 0 ||
      !resp.response.candidates[0].content ||
      !resp.response.candidates[0].content.parts ||
      resp.response.candidates[0].content.parts.length === 0 ||
      !resp.response.candidates[0].content.parts[0].text
    ) {
      throw new Error("Invalid response structure from AI service");
    }

    // Extract the text content
    const analysisText = resp.response.candidates[0].content.parts[0].text;
    // Ensure the response starts with the marker as requested in the prompt
    if (!analysisText.startsWith("[ANALYSIS]:")) {
        functions.logger.warn("AI response did not start with [ANALYSIS]: marker. Prepending it.", { rawResponse: analysisText});
        return `[ANALYSIS]:\n${analysisText}`; // Prepend marker if missing
    }

    return analysisText;
  } catch (error) {
    functions.logger.error("Error calling Vertex AI service:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to call AI service.",
      (error as Error).message,
    );
  }
}

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

      // --- 2. Fetch and Fill Prompt ---
      let promptTemplate: string;
      try {
        // Resolve path relative to the built JS file (in lib/)
        const promptPath = path.resolve(
          __dirname,
          "../src/prompts/negotiation_analysis_prompt.txt", // Adjusted path for build output
        );
        // Note: For deployment, ensure prompts/ folder is included
        //       in the deployment package (check firebase.json functions source)
         if (!fs.existsSync(promptPath)) {
            // Fallback for local development where __dirname might be src/
            const devPath = path.resolve(__dirname, "prompts/negotiation_analysis_prompt.txt");
            if (fs.existsSync(devPath)) {
                promptTemplate = fs.readFileSync(devPath, "utf-8");
            } else {
                 throw new Error(`Prompt file not found at ${promptPath} or ${devPath}`);
            }
        } else {
            promptTemplate = fs.readFileSync(promptPath, "utf-8");
        }

      } catch (err) {
        functions.logger.error("Error reading prompt template file:", err);
        throw new functions.https.HttpsError(
          "internal",
          "Could not load analysis prompt template.",
        );
      }

      const filledPrompt = promptTemplate.replace("{{USER_MESSAGE}}", message);

      // --- 3. Call AI Service ---
      functions.logger.info(
        `Calling AI service for conversation ${conversationId}`,
        {structuredData: true},
      );
      const analysisText = await callAIService(filledPrompt); // Get raw text

      // --- 4. Store Analysis Text in Conversation Document ---
      const conversationRef = admin.firestore()
        .collection("conversations").doc(conversationId);

      try {
        await conversationRef.update({
          latestAnalysisFeedback: analysisText, // Store the raw AI response text
          lastAnalysisTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.info(
          `Analysis text stored for conversation ${conversationId}`,
          {structuredData: true},
        );
      } catch (dbError) {
        functions.logger.error(
          `Firestore update failed for conversation ${conversationId}:`,
          dbError,
        );
        // Decide if this should be a fatal error for the function
        throw new functions.https.HttpsError(
          "internal",
          "Failed to store analysis result.",
          (dbError as Error).message,
        );
      }

      // --- 5. Return Success ---
      // We don't need to return the analysis itself,
      // as the client will listen to Firestore.
      return {status: "success"};
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