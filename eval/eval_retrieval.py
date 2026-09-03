"""
Retrieval evaluation on pqa_labeled (1k gold examples).
Metrics: Recall@k and MRR@k.

Usage:
  python eval_retrieval.py
"""

import os
import time
import requests
from datasets import load_dataset
from supabase import create_client
from dotenv import load_dotenv
from tqdm import tqdm

load_dotenv()

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
EMBEDDING_SERVICE_URL = os.getenv("EMBEDDING_SERVICE_URL", "http://localhost:8000")
HF_TOKEN = os.getenv("HF_TOKEN")

_client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def _with_retries(fn, attempts: int = 4, base_delay: float = 1.0):
    """Retry transient network failures with exponential backoff.

    A full run makes thousands of sequential calls, so a single dropped
    connection would otherwise discard the whole evaluation.
    """
    for attempt in range(attempts):
        try:
            return fn()
        except Exception as e:
            if attempt == attempts - 1:
                raise
            delay = base_delay * (2**attempt)
            print(f"\n  transient error ({type(e).__name__}), retrying in {delay:.0f}s...")
            time.sleep(delay)


def _embed_query(text: str) -> list[float]:
    def call():
        resp = requests.post(
            f"{EMBEDDING_SERVICE_URL}/embed",
            json={"texts": [text], "kind": "query"},
            timeout=30,
        )
        resp.raise_for_status()
        return resp.json()["embeddings"][0]

    return _with_retries(call)


def _retrieve(embedding: list[float], k: int) -> list[str]:
    def call():
        result = _client.rpc(
            "match_documents",
            {"query_embedding": embedding, "match_count": k},
        ).execute()
        return [r["pubid"] for r in result.data]

    return _with_retries(call)


def recall_at_k(dataset, k: int = 5) -> float:
    hits = 0
    for row in tqdm(dataset, desc=f"Recall@{k}"):
        pubid = str(row["pubid"])
        embedding = _embed_query(row["question"])
        if pubid in _retrieve(embedding, k):
            hits += 1
    return hits / len(dataset)


def mrr_at_k(dataset, k: int = 10) -> float:
    rr_sum = 0.0
    for row in tqdm(dataset, desc=f"MRR@{k}"):
        pubid = str(row["pubid"])
        embedding = _embed_query(row["question"])
        for rank, pid in enumerate(_retrieve(embedding, k), start=1):
            if pid == pubid:
                rr_sum += 1 / rank
                break
    return rr_sum / len(dataset)


if __name__ == "__main__":
    dataset = load_dataset("qiaojin/PubMedQA", "pqa_labeled", split="train", token=HF_TOKEN)
    r5 = recall_at_k(dataset, k=5)
    mrr10 = mrr_at_k(dataset, k=10)
    print(f"\nRecall@5 : {r5:.3f}")
    print(f"MRR@10   : {mrr10:.3f}")
