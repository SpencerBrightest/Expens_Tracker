import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

const geminiKey = defineSecret("GEMINI_API_KEY");

const PROMPT =
  "Rewrite this expense note as a 6-word-max, lowercase, " +
  "plain expense label. Reply with ONLY the label, no quotes: ";

/**
 * Authenticated Gemini proxy for Ndoh long-note cleanup.
 * Client sends {note}; the Gemini key stays in the Functions secret.
 * Failures fall back to the caller's note so Save never breaks.
 */
export const getGeminiSummary = onRequest(
  {region: "us-central1", secrets: [geminiKey]},
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send({error: "method-not-allowed"});
      return;
    }
    const auth = req.headers.authorization ?? "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
    if (!token) {
      res.status(401).send({error: "unauthorized"});
      return;
    }
    try {
      await admin.auth().verifyIdToken(token);
    } catch {
      res.status(401).send({error: "unauthorized"});
      return;
    }

    const raw = req.body?.note;
    const note = (typeof raw === "string" ? raw : "").slice(0, 280);

    try {
      const r = await fetch(
        "https://generativelanguage.googleapis.com/v1beta/models/" +
          "gemini-2.0-flash:generateContent",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": geminiKey.value(),
          },
          body: JSON.stringify({
            contents: [{parts: [{text: `${PROMPT}${note}`}]}],
          }),
        }
      );
      if (!r.ok) {
        res.status(200).send({summary: note});
        return;
      }
      const data = (await r.json()) as {
        candidates?: Array<{
          content?: {parts?: Array<{text?: unknown}>};
        }>;
      };
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      const cleaned =
        typeof text === "string" && text.trim() ? text.trim() : note;
      res.status(200).send({summary: cleaned});
    } catch {
      res.status(200).send({summary: note});
    }
  }
);
