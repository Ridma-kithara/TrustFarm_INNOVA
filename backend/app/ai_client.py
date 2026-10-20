import httpx

from .config import settings


def _post(path: str, history: list[dict]) -> dict:
    r = httpx.post(f"{settings.ai_url}{path}", json={"history": history}, timeout=15)
    r.raise_for_status()
    return r.json()


def trust(history):
    try:
        return _post("/trust", history)
    except Exception as e:
        return {"level": "Amber", "score": 50,
                "flags": [{"code": "AI_UNAVAILABLE", "message": str(e), "penalty": 50}]}


def predict(history):
    try:
        return _post("/predict", history)
    except Exception as e:
        return {"forecast_soil": None, "need": None, "reason": f"AI service unavailable: {e}"}
