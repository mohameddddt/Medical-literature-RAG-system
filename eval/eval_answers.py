"""
Answer quality evaluation on pqa_labeled (1k gold examples).
Compares the API's answer against the gold final_decision (yes/no/maybe).

The API is asked for an explicit verdict line ("ANSWER: yes|no|maybe") so that
scoring is deterministic. Inferring a stance from free prose is unreliable —
substring matching in particular misfires on words like "not", "diagnosis" and
"normal", all of which contain "no".

Usage:
  python eval_answers.py            # full 1000-example run
  python eval_answers.py 50         # first 50 examples only
"""

import os
import re
import sys
import time
import requests
from collections import Counter
from datasets import load_dataset
from dotenv import load_dotenv
from tqdm import tqdm

load_dotenv()

API_URL = os.getenv("API_URL", "http://localhost:8080")
HF_TOKEN = os.getenv("HF_TOKEN")

LABELS = ("yes", "no", "maybe")

# Matches the structured verdict the API emits when `verdict: true` is sent.
_VERDICT_RE = re.compile(r"^\s*answer\s*:\s*(yes|no|maybe)\b", re.IGNORECASE)

# Fallback only. Word boundaries stop "not"/"diagnosis"/"normal" matching "no".
_LEADING_RE = re.compile(r"^\W*(yes|no|maybe)\b", re.IGNORECASE)

# Phrases indicating the system declined rather than reached a verdict.
_DECLINE_RE = re.compile(
    r"do(es)? not contain|not enough information|insufficient information|"
    r"cannot be (answered|determined)|no information|do not provide",
    re.IGNORECASE,
)


def _with_retries(fn, attempts: int = 4, base_delay: float = 1.0):
    """Retry transient network failures with exponential backoff."""
    for attempt in range(attempts):
        try:
            return fn()
        except Exception as e:
            if attempt == attempts - 1:
                raise
            delay = base_delay * (2**attempt)
            print(f"\n  transient error ({type(e).__name__}), retrying in {delay:.0f}s...")
            time.sleep(delay)


def _query_api(question: str, verdict: bool = True) -> str:
    def call():
        resp = requests.post(
            f"{API_URL}/api/query",
            json={"question": question, "verdict": verdict},
            timeout=60,
        )
        resp.raise_for_status()
        return resp.json()["answer"]

    return _with_retries(call)


def classify(answer_text: str) -> str | None:
    """Extract the model's verdict.

    Returns "yes"/"no"/"maybe", or None when no verdict could be determined
    (counted separately rather than silently scored as a wrong answer).
    """
    if not answer_text:
        return None

    # 1. The structured verdict line, when present, is authoritative.
    for line in answer_text.strip().splitlines():
        if not line.strip():
            continue
        m = _VERDICT_RE.match(line)
        if m:
            return m.group(1).lower()
        break  # only inspect the first non-empty line

    # 2. Fallback: a leading "Yes,"/"No,"/"Maybe" token.
    m = _LEADING_RE.match(answer_text.strip())
    if m:
        return m.group(1).lower()

    # 3. An explicit refusal maps to "maybe" (insufficient evidence).
    if _DECLINE_RE.search(answer_text):
        return "maybe"

    return None


# Backwards-compatible alias for the previous private helper name.
_classify = classify


def main() -> None:
    n = int(sys.argv[1]) if len(sys.argv) > 1 else None
    split = f"train[:{n}]" if n else "train"
    dataset = load_dataset("qiaojin/PubMedQA", "pqa_labeled", split=split, token=HF_TOKEN)
    total = len(dataset)

    correct = 0
    unparsed = 0
    errors = 0
    confusion: Counter = Counter()
    t0 = time.time()

    for row in tqdm(dataset, desc="Evaluating answers"):
        gold = row["final_decision"]
        try:
            pred = classify(_query_api(row["question"]))
        except Exception as e:
            print(f"\n  Error for pubid {row['pubid']}: {e}")
            errors += 1
            pred = None

        if pred is None:
            unparsed += 1
        elif pred == gold:
            correct += 1
        confusion[(gold, pred or "unparsed")] += 1

    scored = total - unparsed
    elapsed = time.time() - t0

    print(f"\n{'=' * 46}")
    print(f"Examples evaluated : {total}")
    print(f"Verdict returned   : {scored} ({scored / total:.1%} coverage)")
    print(f"No verdict parsed  : {unparsed}")
    print(f"Request errors     : {errors}")
    print(f"{'-' * 46}")
    print(f"Accuracy (all)     : {correct / total:.3f}  ({correct}/{total})")
    if scored:
        print(f"Accuracy (scored)  : {correct / scored:.3f}  ({correct}/{scored})")
    print(f"Elapsed            : {elapsed:.0f}s ({elapsed / total:.1f}s per question)")

    print("\nGold -> predicted:")
    for gold in LABELS:
        for pred in (*LABELS, "unparsed"):
            count = confusion.get((gold, pred), 0)
            if count:
                print(f"  {gold:6} -> {pred:8} : {count}")


if __name__ == "__main__":
    main()
