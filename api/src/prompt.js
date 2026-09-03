const DISCLAIMER =
  'Note: This is for research/educational purposes only and is not medical advice.';

/// Base instructions shared by every request.
const BASE_RULES = `You are a clinical evidence assistant. Answer the user's question using ONLY the numbered passages provided below.
- Cite every claim with its passage number in brackets, e.g. [1], [2].
- If the passages do not contain enough information to answer, say so explicitly — do not speculate or use outside knowledge.
- Be concise and precise.
- End every response with: "${DISCLAIMER}"`;

/// Extra instruction used by the evaluation harness. Asking the model to state
/// an explicit verdict makes scoring deterministic; parsing a verdict out of
/// free prose is not reliable.
// Measured on 200 pqa_labeled examples: accuracy 0.650 (majority baseline 0.560).
// An attempt to raise "maybe" recall by listing hedge words ("may", "suggests")
// as maybe-signals backfired badly — those words appear in nearly every abstract,
// so accuracy fell to 0.455. Re-measure before changing this wording.
const VERDICT_RULE = `
- Begin your response with a single line of exactly the form "ANSWER: yes", "ANSWER: no", or "ANSWER: maybe", reflecting your overall verdict on the question. Use "maybe" when the evidence is mixed, qualified, or insufficient. Then continue with your explanation on the following lines.`;

/**
 * @param {{requireVerdict?: boolean}} [options]
 */
export function buildSystemPrompt(options = {}) {
  const { requireVerdict = false } = options;
  return requireVerdict ? `${BASE_RULES}${VERDICT_RULE}` : BASE_RULES;
}

export function formatContext(passages) {
  return passages
    .map((p, i) => `[${i + 1}] PubMed ID ${p.pubid}\n${p.content}`)
    .join('\n\n');
}
