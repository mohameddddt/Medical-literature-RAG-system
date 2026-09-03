from datasets import load_dataset as hf_load_dataset
from config import HF_DATASET, HF_CONFIG, HF_TOKEN


def load_pubmedqa():
    return hf_load_dataset(HF_DATASET, HF_CONFIG, split="train", token=HF_TOKEN)


def flatten_passages(dataset) -> list[dict]:
    """One row per passage.

    Indexes every section of the abstract, including the conclusion. The
    conclusion (`long_answer`) is what `final_decision` summarises, so leaving
    it out forces the model to infer a verdict from raw results alone.
    """
    passages = []
    for row in dataset:
        pubid = str(row["pubid"])
        question = row["question"]
        context = row["context"]
        contexts = context["contexts"]
        # `labels` runs parallel to `contexts` (BACKGROUND, METHODS, RESULTS...)
        labels = context.get("labels") or []
        # MeSH terms are nested under `context`, not at the top level.
        meshes = context.get("meshes") or []
        final_decision = row.get("final_decision", "")

        def _add(text: str, section: str) -> None:
            if text and text.strip():
                passages.append({
                    "pubid": pubid,
                    "question": question,
                    "content": text.strip(),
                    "metadata": {
                        "final_decision": final_decision,
                        "meshes": meshes,
                        "section": section,
                    },
                })

        for i, ctx in enumerate(contexts):
            _add(ctx, labels[i] if i < len(labels) else "")

        _add(row.get("long_answer") or "", "CONCLUSIONS")

    return passages
