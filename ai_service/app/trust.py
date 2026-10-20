"""AI Trust Engine: basic checks + cross-sensor checks + learned anomaly score."""
import pandas as pd
from .features import TRUST_FEATURES, trust_features

STALE_MIN = 15


def _flag(code, msg, penalty):
    return {"code": code, "message": msg, "penalty": penalty}


def evaluate(raw: pd.DataFrame, now: pd.Timestamp, iso=None, threshold=None) -> dict:
    """raw: DatetimeIndex (UTC), columns soil1, soil2, temp, hum, rain."""
    if raw.empty:
        return {"level": "Red", "score": 0.0,
                "flags": [_flag("NO_DATA", "No readings available", 100)]}
    flags = []
    last = raw.iloc[-1]
    age = (now - raw.index[-1]).total_seconds() / 60
    if age > STALE_MIN:
        flags.append(_flag("STALE", f"Last reading is {age:.0f} min old", 60))

    for c in ("soil1", "soil2"):
        v = last[c]
        if pd.isna(v):
            flags.append(_flag("MISSING", f"{c} missing", 40))
        elif not 0 <= v <= 100:
            flags.append(_flag("RANGE", f"{c}={v:.1f} impossible", 60))

    tail = raw.tail(12)
    for c in ("soil1", "soil2"):
        if len(tail) >= 12 and tail[c].notna().all() and tail[c].nunique() == 1:
            flags.append(_flag("STUCK", f"{c} unchanged for 12 readings", 35))
        d = raw[c].diff().abs()
        if len(d) > 1 and pd.notna(d.iloc[-1]) and d.iloc[-1] > 15:
            flags.append(_flag("JUMP", f"{c} jumped {d.iloc[-1]:.1f} points", 30))

    if pd.notna(last["soil1"]) and pd.notna(last["soil2"]):
        diff = abs(last["soil1"] - last["soil2"])
        if diff > 25:
            flags.append(_flag("MISMATCH", f"Sensors disagree by {diff:.1f}", 40))
        elif diff > 15:
            flags.append(_flag("MISMATCH", f"Sensors disagree by {diff:.1f}", 20))

    # expected soil response to rainfall
    hour = raw[raw.index > raw.index[-1] - pd.Timedelta(hours=1)]
    if len(hour) > 2 and hour["rain"].sum() > 2:
        for c in ("soil1", "soil2"):
            if hour[c].iloc[-1] - hour[c].iloc[0] <= -1:
                flags.append(_flag("NO_RAIN_RESPONSE", f"{c} fell during rain", 15))

    # learned anomaly detector on 5-min resampled data
    if iso is not None and threshold is not None:
        res = raw[["soil1", "soil2"]].resample("5min").mean().interpolate(limit=3)
        tf = trust_features(res).dropna()
        if len(tf):
            s = float(iso.decision_function(tf[TRUST_FEATURES].iloc[[-1]])[0])
            if s < threshold:
                flags.append(_flag("ANOMALY", f"Anomaly model score {s:.3f}", 25))

    score = max(0.0, 100.0 - sum(f["penalty"] for f in flags))
    level = "Green" if score >= 80 else "Amber" if score >= 50 else "Red"
    return {"level": level, "score": score, "flags": flags}
