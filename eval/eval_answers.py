"""
Answer quality evaluation on pqa_labeled (1k gold examples).
Compares the API's answer against the gold final_decision (yes/no/maybe).

Usage:
  python eval_answers.py
"""

import os
import requests
from datasets import load_dataset
from dotenv import load_dotenv
from tqdm import tqdm

load_dotenv()

API_URL = os.getenv("API_URL", "http://localhost:8080")
HF_TOKEN = os.getenv("HF_TOKEN")


def _query_api(question: str) -> str:
    resp = requests.post(
        f"{API_URL}/api/query",
        json={"question": question},
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["answer"]


def _classify(answer_text: str) -> str:
    """Heuristic: look for yes/no/maybe in the first 150 chars of the answer."""
    snippet = answer_text.lower()[:150]
    if "yes" in snippet:
        return "yes"
    if "no" in snippet:
        return "no"
    return "maybe"


if __name__ == "__main__":
    dataset = load_dataset("qiaojin/PubMedQA", "pqa_labeled", split="train", token=HF_TOKEN)

    correct = 0
    for row in tqdm(dataset, desc="Evaluating answers"):
        gold = row["final_decision"]
        try:
            answer = _query_api(row["question"])
            pred = _classify(answer)
        except Exception as e:
            print(f"  Error for pubid {row['pubid']}: {e}")
            pred = "maybe"

        if pred == gold:
            correct += 1

    accuracy = correct / len(dataset)
    print(f"\nAnswer accuracy vs final_decision: {accuracy:.3f}  ({correct}/{len(dataset)})")
