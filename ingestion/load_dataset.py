from datasets import load_dataset as hf_load_dataset
from config import HF_DATASET, HF_CONFIG, HF_TOKEN


def load_pubmedqa():
    return hf_load_dataset(HF_DATASET, HF_CONFIG, split="train", token=HF_TOKEN)


def flatten_passages(dataset) -> list[dict]:
    passages = []
    for row in dataset:
        pubid = str(row["pubid"])
        question = row["question"]
        contexts = row["context"]["contexts"]
        final_decision = row.get("final_decision", "")
        meshes = row.get("meshes", []) or []

        for ctx in contexts:
            if ctx and ctx.strip():
                passages.append({
                    "pubid": pubid,
                    "question": question,
                    "content": ctx.strip(),
                    "metadata": {
                        "final_decision": final_decision,
                        "meshes": meshes,
                    },
                })
    return passages
