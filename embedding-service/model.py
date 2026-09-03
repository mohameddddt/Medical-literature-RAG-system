import os
import torch
from transformers import AutoTokenizer, AutoModel
from dotenv import load_dotenv

load_dotenv()

QUERY_MODEL = os.getenv("QUERY_MODEL", "ncbi/MedCPT-Query-Encoder")
ARTICLE_MODEL = os.getenv("ARTICLE_MODEL", "ncbi/MedCPT-Article-Encoder")
MAX_LENGTH = int(os.getenv("MAX_LENGTH", "512"))


class EmbeddingModels:
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        self.query_tokenizer = AutoTokenizer.from_pretrained(QUERY_MODEL)
        self.query_model = AutoModel.from_pretrained(QUERY_MODEL).to(self.device)
        self.query_model.eval()

        self.article_tokenizer = AutoTokenizer.from_pretrained(ARTICLE_MODEL)
        self.article_model = AutoModel.from_pretrained(ARTICLE_MODEL).to(self.device)
        self.article_model.eval()

    def encode(self, texts: list[str], kind: str) -> list[list[float]]:
        if kind == "query":
            tokenizer = self.query_tokenizer
            model = self.query_model
            max_len = 64
        else:
            tokenizer = self.article_tokenizer
            model = self.article_model
            max_len = MAX_LENGTH

        with torch.no_grad():
            encoded = tokenizer(
                texts,
                truncation=True,
                padding=True,
                max_length=max_len,
                return_tensors="pt",
            ).to(self.device)
            outputs = model(**encoded)
            # CLS token is the passage/query representation for MedCPT
            embeddings = outputs.last_hidden_state[:, 0, :]

        return embeddings.cpu().tolist()


models = EmbeddingModels()
