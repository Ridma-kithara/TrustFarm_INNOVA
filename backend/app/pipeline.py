"""Sense -> Verify -> Predict -> Explain -> Advise -> Energy check -> Store."""
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from . import ai_client, energy
from .models import Alert, EnergyRecord, Reading, Recommendation, TrustResult

HISTORY_HOURS = 7


def _history(db: Session, zone_id: int) -> list[dict]:
    since = datetime.now(timezone.utc) - timedelta(hours=HISTORY_HOURS)
    rows = db.scalars(select(Reading).where(Reading.zone_id == zone_id, Reading.ts >= since)
                      .order_by(Reading.ts)).all()
    return [{"ts": r.ts.isoformat(), "soil1": r.soil1, "soil2": r.soil2,
             "temp": r.temp, "hum": r.hum, "rain": r.rain or 0.0} for r in rows]


def _alert(db: Session, zone_id: int, severity: str, message: str):
    since = datetime.now(timezone.utc) - timedelta(minutes=30)
    dup = db.scalar(select(Alert.id).where(Alert.zone_id == zone_id, Alert.message == message,
                                           Alert.ts >= since))
    if not dup:
        db.add(Alert(zone_id=zone_id, severity=severity, message=message))


def process_reading(db: Session, zone_id: int, d: dict) -> dict:
    ts = d.get("ts")
    ts = datetime.fromtimestamp(ts, timezone.utc) if isinstance(ts, (int, float)) else datetime.now(timezone.utc)
    reading = Reading(zone_id=zone_id, ts=ts, **{k: d.get(k) for k in
                      ("soil1", "soil2", "temp", "hum", "rain", "flow", "batt_v", "batt_soc", "gen_w", "load_w")})
    db.add(reading)
    db.commit()

    history = _history(db, zone_id)
    trust = ai_client.trust(history)
    db.add(TrustResult(zone_id=zone_id, level=trust["level"], score=trust["score"], flags=trust["flags"]))

    en = energy.decide(reading.batt_soc, reading.gen_w, reading.load_w)
    db.add(EnergyRecord(zone_id=zone_id, gen_w=reading.gen_w, load_w=reading.load_w,
                        batt_soc=reading.batt_soc, mode=en["mode"],
                        irrigation_ok=en["irrigation_ok"], message=en["message"]))
    if en["mode"] == "PROTECT":
        _alert(db, zone_id, "warning", en["message"])

    level = trust["level"]
    if level == "Red":
        names = ", ".join(f["message"] for f in trust["flags"][:3])
        rec = Recommendation(zone_id=zone_id, need=None, irrigate=False,
                             advice="Irrigation advice paused - sensor data not trusted",
                             reason=f"Data Trust is Red: {names}")
        _alert(db, zone_id, "critical", f"Sensor fault suspected: {names}")
    else:
        pred = ai_client.predict(history)
        need = pred.get("need")
        reason = pred.get("reason") or ""
        if level == "Amber":
            advice = "Please check the sensors manually before irrigating"
            irrigate = False
            reason = "Data Trust is Amber (cautious guidance). " + reason
            _alert(db, zone_id, "warning", "Data Trust Amber - quick sensor check recommended")
        elif need == "High" and en["irrigation_ok"]:
            advice, irrigate = "Irrigate now", True
        elif need == "High":
            advice, irrigate = "Irrigation needed but energy is low - delay or use manual supply", False
            reason += " " + en["message"] + "."
        elif need == "Medium":
            advice, irrigate = "Prepare to irrigate soon", False
        else:
            advice, irrigate = "No irrigation needed", False
        rec = Recommendation(zone_id=zone_id, need=need, forecast_soil=pred.get("forecast_soil"),
                             irrigate=irrigate, advice=advice, reason=reason)
    db.add(rec)
    db.commit()
    return {"trust": trust, "energy": en, "advice": rec.advice}
