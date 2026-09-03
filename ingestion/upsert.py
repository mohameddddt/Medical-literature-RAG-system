from supabase import create_client
from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, BATCH_SIZE

_client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def upsert_all(passages: list[dict], embeddings: list[list[float]]) -> None:
    for i in range(0, len(passages), BATCH_SIZE):
        batch_p = passages[i : i + BATCH_SIZE]
        batch_e = embeddings[i : i + BATCH_SIZE]
        rows = [
            {
                "pubid": p["pubid"],
                "question": p["question"],
                "content": p["content"],
                "metadata": p["metadata"],
                "embedding": emb,
            }
            for p, emb in zip(batch_p, batch_e)
        ]
        _client.table("documents").insert(rows).execute()
        print(f"  Upserted rows {i + 1}–{i + len(batch_p)}")
