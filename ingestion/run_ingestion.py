from tqdm import tqdm
from config import BATCH_SIZE
from load_dataset import load_pubmedqa, flatten_passages
from chunk import clean_passages
from embed import embed_batch
from upsert import upsert_all


def run():
    print("Loading dataset...")
    dataset = load_pubmedqa()
    print(f"  {len(dataset)} rows loaded.")

    print("Flattening passages...")
    passages = flatten_passages(dataset)
    print(f"  {len(passages)} passages before cleaning.")

    passages = clean_passages(passages)
    print(f"  {len(passages)} passages after deduplication.")

    print("Embedding in batches...")
    embeddings: list[list[float]] = []
    for i in tqdm(range(0, len(passages), BATCH_SIZE), desc="Embedding"):
        batch_texts = [p["content"] for p in passages[i : i + BATCH_SIZE]]
        embeddings.extend(embed_batch(batch_texts, kind="article"))

    print("Upserting to Supabase...")
    upsert_all(passages, embeddings)
    print("Done.")


if __name__ == "__main__":
    run()
