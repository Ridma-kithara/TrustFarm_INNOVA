from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from . import energy, mqtt_client
from .auth import current_user, hash_password, make_token, require_roles, verify_password
from .config import settings
from .db import SessionLocal, get_db
from .models import (Alert, EnergyRecord, Farm, Reading, Recommendation, TrustResult, User, Zone)
from .pipeline import process_reading


@asynccontextmanager
async def lifespan(app: FastAPI):
    with SessionLocal() as db:  # seed admin
        if not db.scalar(select(User).where(User.email == settings.admin_email)):
            db.add(User(email=settings.admin_email, name="Admin", role="admin",
                        password_hash=hash_password(settings.admin_password)))
            db.commit()
    client = mqtt_client.start()
    yield
    client.loop_stop()


app = FastAPI(title="TrustFarm API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


# ---------- schemas ----------
class LoginIn(BaseModel):
    email: EmailStr
    password: str


class UserIn(BaseModel):
    email: EmailStr
    name: str
    password: str
    role: str = "farmer"
    farm_id: Optional[int] = None


class TelemetryIn(BaseModel):
    ts: Optional[float] = None
    soil1: Optional[float] = None
    soil2: Optional[float] = None
    temp: Optional[float] = None
    hum: Optional[float] = None
    rain: Optional[float] = None
    flow: Optional[float] = None
    batt_v: Optional[float] = None
    batt_soc: Optional[float] = None
    gen_w: Optional[float] = None
    load_w: Optional[float] = None


# ---------- helpers ----------
def row(o, *cols):
    return {c: getattr(o, c) for c in cols}


def zone_for(db: Session, zone_id: int, user: User) -> Zone:
    z = db.get(Zone, zone_id)
    if not z:
        raise HTTPException(404, "Zone not found")
    if user.role == "farmer" and user.farm_id != z.farm_id:
        raise HTTPException(403, "Not your farm")
    return z


def latest(db, model, zone_id):
    return db.scalar(select(model).where(model.zone_id == zone_id).order_by(desc(model.id)).limit(1))


# ---------- auth ----------
@app.post("/auth/login")
def login(body: LoginIn, db: Session = Depends(get_db)):
    u = db.scalar(select(User).where(User.email == body.email))
    if not u or not verify_password(body.password, u.password_hash):
        raise HTTPException(401, "Wrong email or password")
    return {"token": make_token(u), "user": row(u, "id", "email", "name", "role", "farm_id")}


@app.get("/me")
def me(user: User = Depends(current_user)):
    return row(user, "id", "email", "name", "role", "farm_id")


# ---------- farms / zones ----------
@app.get("/zones")
def zones(user: User = Depends(current_user), db: Session = Depends(get_db)):
    q = select(Zone, Farm).join(Farm, Farm.id == Zone.farm_id)
    if user.role == "farmer":
        q = q.where(Zone.farm_id == user.farm_id)
    return [{"id": z.id, "name": z.name, "farm_id": f.id, "farm": f.name, "crop": f.crop}
            for z, f in db.execute(q)]


@app.get("/zones/{zone_id}/status")
def status(zone_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)):
    zone_for(db, zone_id, user)
    r = latest(db, Reading, zone_id)
    t = latest(db, TrustResult, zone_id)
    rec = latest(db, Recommendation, zone_id)
    return {
        "reading": row(r, "ts", "soil1", "soil2", "temp", "hum", "rain", "flow",
                       "batt_v", "batt_soc", "gen_w", "load_w") if r else None,
        "trust": row(t, "ts", "level", "score", "flags") if t else None,
        "recommendation": row(rec, "ts", "need", "forecast_soil", "irrigate", "advice", "reason") if rec else None,
        "energy": energy.decide(r.batt_soc, r.gen_w, r.load_w) if r else None,
    }


@app.get("/zones/{zone_id}/readings")
def readings(zone_id: int, hours: int = 24, user: User = Depends(current_user),
             db: Session = Depends(get_db)):
    zone_for(db, zone_id, user)
    since = datetime.now(timezone.utc) - timedelta(hours=min(hours, 168))
    rows = db.scalars(select(Reading).where(Reading.zone_id == zone_id, Reading.ts >= since)
                      .order_by(Reading.ts)).all()
    return [row(r, "ts", "soil1", "soil2", "temp", "hum", "rain", "flow",
                "batt_soc", "gen_w", "load_w") for r in rows]


@app.get("/zones/{zone_id}/trust-history")
def trust_history(zone_id: int, hours: int = 24, user: User = Depends(current_user),
                  db: Session = Depends(get_db)):
    zone_for(db, zone_id, user)
    since = datetime.now(timezone.utc) - timedelta(hours=min(hours, 168))
    rows = db.scalars(select(TrustResult).where(TrustResult.zone_id == zone_id, TrustResult.ts >= since)
                      .order_by(TrustResult.ts)).all()
    return [row(r, "ts", "level", "score") for r in rows]


@app.get("/alerts")
def alerts(user: User = Depends(current_user), db: Session = Depends(get_db)):
    q = select(Alert).join(Zone, Zone.id == Alert.zone_id, isouter=True).order_by(desc(Alert.id)).limit(50)
    if user.role == "farmer":
        q = q.where(Zone.farm_id == user.farm_id)
    return [row(a, "id", "zone_id", "ts", "severity", "message", "acknowledged") for a in db.scalars(q)]


# ---------- device HTTP fallback ----------
@app.post("/zones/{zone_id}/telemetry")
def telemetry(zone_id: int, body: TelemetryIn, user: User = Depends(require_roles("admin")),
              db: Session = Depends(get_db)):
    if not db.get(Zone, zone_id):
        raise HTTPException(404, "Zone not found")
    return process_reading(db, zone_id, body.model_dump())


# ---------- officer ----------
@app.get("/officer/zones")
def officer_zones(user: User = Depends(require_roles("officer", "admin")), db: Session = Depends(get_db)):
    out = []
    for z in db.scalars(select(Zone)):
        r, t = latest(db, Reading, z.id), latest(db, TrustResult, z.id)
        out.append({"zone_id": z.id, "zone": z.name, "farm_id": z.farm_id,
                    "last_seen": r.ts if r else None, "trust": t.level if t else None,
                    "score": t.score if t else None, "flags": t.flags if t else [],
                    "batt_soc": r.batt_soc if r else None})
    return out


# ---------- admin ----------
@app.get("/admin/users")
def list_users(user: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    return [row(u, "id", "email", "name", "role", "farm_id") for u in db.scalars(select(User))]


@app.post("/admin/users")
def create_user(body: UserIn, user: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    if body.role not in ("farmer", "officer", "admin"):
        raise HTTPException(400, "Invalid role")
    if db.scalar(select(User).where(User.email == body.email)):
        raise HTTPException(409, "Email already exists")
    u = User(email=body.email, name=body.name, role=body.role, farm_id=body.farm_id,
             password_hash=hash_password(body.password))
    db.add(u)
    db.commit()
    return row(u, "id", "email", "name", "role", "farm_id")


@app.get("/health")
def health():
    return {"ok": True}
