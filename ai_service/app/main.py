import json, os
from datetime import datetime, timezone
from typing import Optional

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel

from . import trust as trust_engine
from .features import (FORECAST_FEATURES, MEDIUM_BELOW, HIGH_BELOW, WILTING,
                       build_features, need_from_soil)

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "models")
app = FastAPI(title="TrustFarm AI API")
M = {}


def _load():
    try:
        M["reg"] = joblib.load(f"{MODEL_DIR}/forecast.joblib")
        M["clf"] = joblib.load(f"{MODEL_DIR}/classifier.joblib")
        M["iso"] = joblib.load(f"{MODEL_DIR}/anomaly.joblib")
        M["meta"] = json.load(open(f"{MODEL_DIR}/meta.json"))
    except Exception as e:  # models not trained yet -> rule-based fallback
        print("Models not loaded:", e)


_load()


class Reading(BaseModel):
    ts: datetime
    soil1: Optional[float] = None
    soil2: Optional[float] = None
    temp: Optional[float] = None
    hum: Optional[float] = None
    rain: Optional[float] = 0.0


class HistoryIn(BaseModel):
    history: list[Reading]


def to_df(history: list[Reading]) -> pd.DataFrame:
    df = pd.DataFrame([r.model_dump() for r in history])
    if df.empty:
        return pd.DataFrame(columns=["soil1", "soil2", "temp", "hum", "rain"])
    df["ts"] = pd.to_datetime(df["ts"], utc=True)
    return df.set_index("ts").sort_index()


@app.get("/health")
def health():
    return {"ok": True, "models_loaded": "reg" in M}


@app.post("/trust")
def trust(body: HistoryIn):
    raw = to_df(body.history)
    now = pd.Timestamp(datetime.now(timezone.utc))
    return trust_engine.evaluate(raw, now, M.get("iso"),
                                 M.get("meta", {}).get("anomaly_threshold"))


@app.post("/predict")
def predict(body: HistoryIn):
    raw = to_df(body.history)
    if raw.empty:
        return {"forecast_soil": None, "need": None, "reason": "No data", "factors": {}}
    res = pd.DataFrame({
        "soil": raw[["soil1", "soil2"]].mean(axis=1).resample("5min").mean(),
        "temp": raw["temp"].resample("5min").mean(),
        "hum": raw["hum"].resample("5min").mean(),
        "rain": raw["rain"].fillna(0).resample("5min").sum(),
    }).interpolate(limit=6).ffill()
    f = build_features(res).iloc[[-1]].fillna(0)
    soil = float(f["soil"].iloc[0])

    if "reg" in M:
        forecast = float(M["reg"].predict(f[FORECAST_FEATURES])[0])
        need = str(M["clf"].predict(f[FORECAST_FEATURES])[0])
    else:  # fallback: persistence + trend
        forecast = soil + float(f["d1h"].iloc[0]) * 3
        need = need_from_soil(forecast)

    # crop-specific safety rule overrides the model
    if soil < WILTING:
        need = "High"
    elif need == "Low" and soil < HIGH_BELOW:
        need = "Medium"

    factors = {k: round(float(f[k].iloc[0]), 2) for k in ("soil", "d1h", "rain_6h", "temp")}
    reason = explain(need, soil, forecast, factors)
    return {"forecast_soil": round(forecast, 1), "need": need, "reason": reason, "factors": factors}


def explain(need, soil, forecast, f):
    parts = [f"Soil moisture is {soil:.0f}% and is forecast to be {forecast:.0f}% in about 3 hours"]
    if f["d1h"] < -1:
        parts.append(f"it fell {abs(f['d1h']):.1f} points in the last hour")
    if f["rain_6h"] > 1:
        parts.append(f"{f['rain_6h']:.1f} mm of rain fell recently")
    elif f["temp"] > 32:
        parts.append(f"high temperature ({f['temp']:.0f}°C) speeds up drying")
    limit = {"High": f"below the {HIGH_BELOW:.0f}% limit", "Medium": f"approaching the {MEDIUM_BELOW:.0f}% limit",
             "Low": "within the safe range"}[need]
    return "; ".join(parts) + f". Irrigation need: {need} ({limit})."
