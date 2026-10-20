"""Feature engineering shared by training (train.py) and serving (app/main.py)."""
import numpy as np
import pandas as pd

STEP_MIN = 5
HORIZON_STEPS = 36  # 3 hours ahead at 5-minute resolution

# crop-specific thresholds (soil moisture %) - tune per crop
HIGH_BELOW = 25.0
MEDIUM_BELOW = 35.0
WILTING = 20.0

FORECAST_FEATURES = ["soil", "d15", "d1h", "d6h", "temp", "hum",
                     "rain_1h", "rain_6h", "hour_sin", "hour_cos"]
TRUST_FEATURES = ["abs_diff", "d1_s1", "d1_s2"]


def build_features(df: pd.DataFrame) -> pd.DataFrame:
    """df: 5-min DatetimeIndex with columns soil, temp, hum, rain."""
    f = pd.DataFrame(index=df.index)
    f["soil"] = df["soil"]
    f["d15"] = df["soil"].diff(3)
    f["d1h"] = df["soil"].diff(12)
    f["d6h"] = df["soil"].diff(72)
    f["temp"] = df["temp"]
    f["hum"] = df["hum"]
    f["rain_1h"] = df["rain"].rolling(12, min_periods=1).sum()
    f["rain_6h"] = df["rain"].rolling(72, min_periods=1).sum()
    h = df.index.hour + df.index.minute / 60
    f["hour_sin"] = np.sin(2 * np.pi * h / 24)
    f["hour_cos"] = np.cos(2 * np.pi * h / 24)
    return f


def trust_features(df: pd.DataFrame) -> pd.DataFrame:
    """df: 5-min DatetimeIndex with columns soil1, soil2."""
    t = pd.DataFrame(index=df.index)
    t["abs_diff"] = (df["soil1"] - df["soil2"]).abs()
    t["d1_s1"] = df["soil1"].diff()
    t["d1_s2"] = df["soil2"].diff()
    return t


def need_from_soil(soil: float) -> str:
    if soil < HIGH_BELOW:
        return "High"
    if soil < MEDIUM_BELOW:
        return "Medium"
    return "Low"
