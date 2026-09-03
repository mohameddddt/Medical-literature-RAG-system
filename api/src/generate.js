import { GoogleGenerativeAI } from '@google/generative-ai';
import 'dotenv/config';
import { buildSystemPrompt, formatContext } from './prompt.js';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const MODEL = process.env.LLM_MODEL ?? 'gemini-flash-lite-latest';
const REQUEST_TIMEOUT_MS = 15000;
const RETRY_DELAY_MS = 1000;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export async function generateAnswer(question, passages, options = {}) {
  const { requireVerdict = false } = options;
  const model = genAI.getGenerativeModel({
    model: MODEL,
    systemInstruction: buildSystemPrompt({ requireVerdict }),
  });
  const context = formatContext(passages);
  const prompt = `Passages:\n${context}\n\nQuestion: ${question}`;

  try {
    const result = await model.generateContent(prompt, { timeout: REQUEST_TIMEOUT_MS });
    return result.response.text();
  } catch (err) {
    // One retry for transient failures: timeouts, 5xx, or raw network errors.
    // Anything else (e.g. a bad API key / 4xx) is rethrown immediately since a retry won't help.
    const status = err?.status;
    const isTransient = status === undefined || status === 429 || status >= 500;
    if (!isTransient) throw err;

    console.warn(`generateAnswer: transient error (${status ?? err.message}), retrying once...`);
    await sleep(RETRY_DELAY_MS);
    const result = await model.generateContent(prompt, { timeout: REQUEST_TIMEOUT_MS });
    return result.response.text();
  }
}
