/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest, Request} from "firebase-functions/v2/https";
import {Response} from "express";
import * as logger from "firebase-functions/logger";
import cors from "cors";

// Initialize CORS middleware.
// By default, allows all origins. For production, configure specific origins.
// See https://github.com/expressjs/cors#configuration-options
const corsHandler = cors({origin: true});

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/**
 * Basic health check endpoint.
 * Responds with a 200 OK status and a simple message.
 */
export const healthCheck = onRequest((request: Request, response: Response) => {
  // Handle CORS for the request.
  corsHandler(request, response, () => {
    logger.info("Health check requested!", {structuredData: true});
    response.status(200).send({status: "OK", message: "Firebase is healthy!"});
  });
});
