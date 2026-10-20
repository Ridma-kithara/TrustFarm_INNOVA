"""Train forecast, irrigation-need and anomaly models.

Usage:
  python train.py                      # synthetic demo data
  python train.py --csv data.csv       # columns: ts,soil1,soil2,temp,hum,rain
Replace synthetic data with AquaIntel / AgriField-Manipur / local pilot data
for real claims. Public datasets = development evidence only.
"""
import argparse, json, os
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import (GradientBoostingRegressor, IsolationForest,
                              RandomForestClassifier)
from sklearn.metrics import (classification_report, confusion_matrix,
                             mean_absolute_error, mean_squared_error)
from app.features import (FORECAST_FEATURES, HORIZON_STEPS, TRUST_FEATURES,
                          build_features, need_from_soil, trust_features)

OUT = os.path.join(os.path.dirname(__file__), "models")


def synth(days=90, seed=0) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    n = days * 288
    idx = pd.date_range("2025-01-01", periods=n, freq="5min", tz="UTC")
    soil = np.zeros(n); soil[0] = 40
    temp = 27 + 5 * np.sin(2 * np.pi * (idx.hour + idx.minute / 60 - 9) / 24) + rng.normal(0, .5, n)
    hum = 70 - 2 * (temp - 27) + rng.normal(0, 2, n)
    rain = np.zeros(n)
    pending = 0.0
    for i in range(1, n):
        if rng.random() < 0.0015:
            rain[i] = rng.uniform(1, 8)
        evap = 0.012 + 0.0025 * max(temp[i] - 20, 0) / 5
        s = soil[i - 1] - evap + 0.9 * rain[i]
        if s < 17 and pending <= 0:           # farmer irrigates late, so dry (High-need) periods occur
            pending = 30
        if pending > 0:
            s += 0.9; pending -= 1
        soil[i] = np.clip(s, 5, 60)
    df = pd.DataFrame({"soil": soil, "temp": temp, "hum": hum, "rain": rain}, index=idx)
    df["soil1"] = soil + rng.normal(0, .4, n)
    df["soil2"] = soil + 1.0 + rng.normal(0, .4, n)
    return df


def load(csv):
    if not csv:
        return synth()
    d = pd.read_csv(csv, parse_dates=["ts"]).set_index("ts")
    d.index = pd.to_datetime(d.index, utc=True)
    d = d.resample("5min").mean(numeric_only=True).interpolate(limit=6)
    d["soil"] = d[["soil1", "soil2"]].mean(axis=1)
    return d.dropna()


def inject_faults(df, rng):
    """Return copy with spikes, stuck values and drift in soil2 + boolean mask."""
    d = df.copy(); mask = np.zeros(len(d), bool)
    n = len(d)
    for _ in range(20):
        i = int(rng.integers(100, n - 100)); kind = rng.choice(["spike", "stuck", "drift"])
        if kind == "spike":
            d.iloc[i, d.columns.get_loc("soil2")] += rng.choice([-30, 30]); mask[i] = True
        elif kind == "stuck":
            d.iloc[i:i + 30, d.columns.get_loc("soil2")] = d["soil2"].iloc[i]; mask[i + 6:i + 30] = True
        else:
            d.iloc[i:i + 60, d.columns.get_loc("soil2")] += np.linspace(0, 25, 60); mask[i + 30:i + 60] = True
    return d, mask


def main(csv):
    os.makedirs(OUT, exist_ok=True)
    df = load(csv)
    feats = build_features(df)
    y = df["soil"].shift(-HORIZON_STEPS)
    data = feats.join(y.rename("y")).dropna()
    cut = int(len(data) * 0.8)                        # time-based split, no leakage
    tr, te = data.iloc[:cut], data.iloc[cut:]

    reg = GradientBoostingRegressor(n_estimators=200, max_depth=3, random_state=0)
    reg.fit(tr[FORECAST_FEATURES], tr["y"])
    pred = reg.predict(te[FORECAST_FEATURES])
    base = te["soil"].values                          # persistence baseline
    m = {
        "forecast_mae": float(mean_absolute_error(te["y"], pred)),
        "forecast_rmse": float(mean_squared_error(te["y"], pred) ** .5),
        "baseline_mae": float(mean_absolute_error(te["y"], base)),
        "baseline_rmse": float(mean_squared_error(te["y"], base) ** .5),
    }

    ytr = tr["y"].map(need_from_soil); yte = te["y"].map(need_from_soil)
    clf = RandomForestClassifier(n_estimators=200, class_weight="balanced", random_state=0)
    clf.fit(tr[FORECAST_FEATURES], ytr)
    yp = clf.predict(te[FORECAST_FEATURES])
    labels = ["Low", "Medium", "High"]
    m["classification"] = classification_report(yte, yp, labels=labels, output_dict=True, zero_division=0)
    m["confusion_matrix"] = {"labels": labels, "matrix": confusion_matrix(yte, yp, labels=labels).tolist()}

    # anomaly model trained on normal sensor behaviour only
    tf = trust_features(df).dropna()
    ttr, tte = tf.iloc[:cut], df.iloc[cut:]
    iso = IsolationForest(n_estimators=200, contamination="auto", random_state=0).fit(ttr[TRUST_FEATURES])
    thr = float(np.percentile(iso.decision_function(ttr[TRUST_FEATURES]), 5))
    faulty, mask = inject_faults(tte[["soil1", "soil2"]], np.random.default_rng(1))
    sc = iso.decision_function(trust_features(faulty).fillna(0)[TRUST_FEATURES])
    flagged = sc < thr
    m["anomaly"] = {"threshold": thr,
                    "fault_detection_rate": float(flagged[mask].mean()),
                    "false_alarm_rate": float(flagged[~mask].mean())}

    joblib.dump(reg, f"{OUT}/forecast.joblib")
    joblib.dump(clf, f"{OUT}/classifier.joblib")
    joblib.dump(iso, f"{OUT}/anomaly.joblib")
    json.dump({"anomaly_threshold": thr, "metrics": m}, open(f"{OUT}/meta.json", "w"), indent=2)
    print(json.dumps(m, indent=2))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("--csv")
    main(ap.parse_args().csv)
