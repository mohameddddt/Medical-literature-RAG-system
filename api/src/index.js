import express from 'express';
import cors from 'cors';
import 'dotenv/config';
import { z } from 'zod';
import { embedQuery } from './embedClient.js';
import { retrievePassages } from './retrieve.js';
import { generateAnswer } from './generate.js';

const app = express();
app.use(cors());
app.use(express.json());

const QuerySchema = z.object({
  question: z.string().min(1).max(1000),
  // Opt-in: prefixes the answer with an "ANSWER: yes|no|maybe" line so the
  // evaluation harness can score deterministically. Off by default, so the
  // app's output is unchanged.
  verdict: z.boolean().optional().default(false),
});

app.post('/api/query', async (req, res) => {
  const parsed = QuerySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { question, verdict } = parsed.data;
  try {
    const embedding = await embedQuery(question);
    const passages = await retrievePassages(embedding);
    const answer = await generateAnswer(question, passages, {
      requireVerdict: verdict,
    });
    const sources = passages.map((p) => ({
      pubid: p.pubid,
      similarity: p.similarity,
      snippet: p.content.slice(0, 200),
    }));
    res.json({ answer, sources });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT ?? 8080;
app.listen(PORT, () => console.log(`API listening on :${PORT}`));
