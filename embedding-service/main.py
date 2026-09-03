from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from model import models

app = FastAPI(title="MedCPT Embedding Service")


class EmbedRequest(BaseModel):
    texts: list[str]
    kind: str = "article"  # "article" or "query"


class EmbedResponse(BaseModel):
    embeddings: list[list[float]]
    kind: str
    dim: int


@app.post("/embed", response_model=EmbedResponse)
def embed(req: EmbedRequest):
    if req.kind not in ("article", "query"):
        raise HTTPException(status_code=400, detail="kind must be 'article' or 'query'")
    if not req.texts:
        raise HTTPException(status_code=400, detail="texts must not be empty")

    embeddings = models.encode(req.texts, req.kind)
    return EmbedResponse(
        embeddings=embeddings,
        kind=req.kind,
        dim=len(embeddings[0]) if embeddings else 0,
    )


@app.get("/health")
def health():
    return {"status": "ok"}
