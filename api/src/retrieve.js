import 'dotenv/config';
import { supabase } from './supabase.js';

const MATCH_COUNT = parseInt(process.env.MATCH_COUNT ?? '5');

export async function retrievePassages(queryEmbedding) {
  const { data, error } = await supabase.rpc('match_documents', {
    query_embedding: queryEmbedding,
    match_count: MATCH_COUNT,
  });
  if (error) throw new Error(`Retrieval error: ${error.message}`);
  return data;
}
