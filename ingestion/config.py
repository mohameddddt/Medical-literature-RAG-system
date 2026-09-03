import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
EMBEDDING_SERVICE_URL = os.getenv("EMBEDDING_SERVICE_URL", "http://localhost:8000")
HF_TOKEN = os.getenv("HF_TOKEN")
HF_DATASET = os.getenv("HF_DATASET", "qiaojin/PubMedQA")
HF_CONFIG = os.getenv("HF_CONFIG", "pqa_labeled")
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "64"))
