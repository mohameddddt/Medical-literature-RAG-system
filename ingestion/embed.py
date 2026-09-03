import requests
from config import EMBEDDING_SERVICE_URL


def embed_batch(texts: list[str], kind: str = "article") -> list[list[float]]:
    resp = requests.post(
        f"{EMBEDDING_SERVICE_URL}/embed",
        json={"texts": texts, "kind": kind},
        timeout=120,
    )
    resp.raise_for_status()
    return resp.json()["embeddings"]
