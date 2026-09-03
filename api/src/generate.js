import { GoogleGenerativeAI } from '@google/generative-ai';
import 'dotenv/config';
import { buildSystemPrompt, formatContext } from './prompt.js';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const MODEL = process.env.LLM_MODEL ?? 'gemini-1.5-flash';

export async function generateAnswer(question, passages) {
  const model = genAI.getGenerativeModel({
    model: MODEL,
    systemInstruction: buildSystemPrompt(),
  });
  const context = formatContext(passages);
  const prompt = `Passages:\n${context}\n\nQuestion: ${question}`;
  const result = await model.generateContent(prompt);
  return result.response.text();
}
