"""Energy Management: decide what the farm may do with the available energy."""
from typing import Optional

from .config import settings


def decide(soc: Optional[float], gen_w: Optional[float], load_w: Optional[float]) -> dict:
    gen_w = gen_w or 0.0
    load_w = load_w or 0.0
    surplus = gen_w - load_w
    if soc is None:
        return {"mode": "UNKNOWN", "irrigation_ok": False, "surplus_w": surplus,
                "message": "Battery data unavailable - irrigation not scheduled automatically"}
    if soc < settings.soc_critical:
        return {"mode": "PROTECT", "irrigation_ok": False, "surplus_w": surplus,
                "message": f"Battery {soc:.0f}% - only critical loads (sensors, network) are supported"}
    if soc < settings.soc_conserve and gen_w < settings.pump_w:
        return {"mode": "CONSERVE", "irrigation_ok": False, "surplus_w": surplus,
                "message": f"Battery {soc:.0f}% and low generation - delay irrigation"}
    mode = "CHARGING" if surplus > 0 else "NORMAL"
    return {"mode": mode, "irrigation_ok": True, "surplus_w": surplus,
            "message": f"Energy available (battery {soc:.0f}%, generation {gen_w:.0f} W)"}
