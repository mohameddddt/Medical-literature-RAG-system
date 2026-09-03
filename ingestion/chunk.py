import re
import unicodedata


def _clean(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    return re.sub(r"\s+", " ", text).strip()


def clean_passages(passages: list[dict]) -> list[dict]:
    seen: set[str] = set()
    result = []
    for p in passages:
        text = _clean(p["content"])
        if len(text) < 20:
            continue
        key = text[:200]
        if key in seen:
            continue
        seen.add(key)
        result.append({**p, "content": text})
    return result
