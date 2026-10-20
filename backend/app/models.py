"""ORM models - must match db/init.sql."""
from datetime import datetime
from typing import Optional

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base

TZ = DateTime(timezone=True)


class Farm(Base):
    __tablename__ = "farms"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(Text)
    location: Mapped[Optional[str]] = mapped_column(Text)
    crop: Mapped[Optional[str]] = mapped_column(Text)


class Zone(Base):
    __tablename__ = "zones"
    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id"))
    name: Mapped[str] = mapped_column(Text)


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(Text, unique=True)
    name: Mapped[Optional[str]] = mapped_column(Text)
    password_hash: Mapped[str] = mapped_column(Text)
    role: Mapped[str] = mapped_column(Text)
    farm_id: Mapped[Optional[int]] = mapped_column(ForeignKey("farms.id"))


class Reading(Base):
    __tablename__ = "readings"
    id: Mapped[int] = mapped_column(primary_key=True)
    zone_id: Mapped[int] = mapped_column(ForeignKey("zones.id"))
    ts: Mapped[datetime] = mapped_column(TZ)
    soil1: Mapped[Optional[float]] = mapped_column(Float)
    soil2: Mapped[Optional[float]] = mapped_column(Float)
    temp: Mapped[Optional[float]] = mapped_column(Float)
    hum: Mapped[Optional[float]] = mapped_column(Float)
    rain: Mapped[Optional[float]] = mapped_column(Float)
    flow: Mapped[Optional[float]] = mapped_column(Float)
    batt_v: Mapped[Optional[float]] = mapped_column(Float)
    batt_soc: Mapped[Optional[float]] = mapped_column(Float)
    gen_w: Mapped[Optional[float]] = mapped_column(Float)
    load_w: Mapped[Optional[float]] = mapped_column(Float)


class TrustResult(Base):
    __tablename__ = "trust_results"
    id: Mapped[int] = mapped_column(primary_key=True)
    zone_id: Mapped[int] = mapped_column(ForeignKey("zones.id"))
    ts: Mapped[datetime] = mapped_column(TZ, default=datetime.utcnow)
    level: Mapped[str] = mapped_column(String)
    score: Mapped[float] = mapped_column(Float)
    flags: Mapped[list] = mapped_column(JSONB, default=list)


class Recommendation(Base):
    __tablename__ = "recommendations"
    id: Mapped[int] = mapped_column(primary_key=True)
    zone_id: Mapped[int] = mapped_column(ForeignKey("zones.id"))
    ts: Mapped[datetime] = mapped_column(TZ, default=datetime.utcnow)
    need: Mapped[Optional[str]] = mapped_column(Text)
    forecast_soil: Mapped[Optional[float]] = mapped_column(Float)
    irrigate: Mapped[bool] = mapped_column(Boolean, default=False)
    advice: Mapped[str] = mapped_column(Text)
    reason: Mapped[Optional[str]] = mapped_column(Text)


class EnergyRecord(Base):
    __tablename__ = "energy_records"
    id: Mapped[int] = mapped_column(primary_key=True)
    zone_id: Mapped[int] = mapped_column(ForeignKey("zones.id"))
    ts: Mapped[datetime] = mapped_column(TZ, default=datetime.utcnow)
    gen_w: Mapped[Optional[float]] = mapped_column(Float)
    load_w: Mapped[Optional[float]] = mapped_column(Float)
    batt_soc: Mapped[Optional[float]] = mapped_column(Float)
    mode: Mapped[str] = mapped_column(Text)
    irrigation_ok: Mapped[bool] = mapped_column(Boolean)
    message: Mapped[Optional[str]] = mapped_column(Text)


class Alert(Base):
    __tablename__ = "alerts"
    id: Mapped[int] = mapped_column(primary_key=True)
    zone_id: Mapped[Optional[int]] = mapped_column(ForeignKey("zones.id"))
    ts: Mapped[datetime] = mapped_column(TZ, default=datetime.utcnow)
    severity: Mapped[str] = mapped_column(Text)
    message: Mapped[str] = mapped_column(Text)
    acknowledged: Mapped[bool] = mapped_column(Boolean, default=False)
