import 'dotenv/config';

const EMBEDDING_SERVICE_URL = process.env.EMBEDDING_SERVICE_URL ?? 'http://localhost:8000';

export async function embedQuery(question) {
  const res = await fetch(`${EMBEDDING_SERVICE_URL}/embed`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ texts: [question], kind: 'query' }),
  });
  if (!res.ok) {
    throw new Error(`Embedding service error: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  return data.embeddings[0];
}
