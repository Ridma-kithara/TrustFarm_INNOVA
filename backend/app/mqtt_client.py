"""Subscribes to trustfarm/zone/<id>/telemetry and runs the pipeline."""
import json, logging, re

import paho.mqtt.client as mqtt

from .config import settings
from .db import SessionLocal
from .pipeline import process_reading

log = logging.getLogger("mqtt")
TOPIC = "trustfarm/zone/+/telemetry"


def _on_connect(client, userdata, flags, reason_code, properties=None):
    log.info("MQTT connected: %s", reason_code)
    client.subscribe(TOPIC, qos=1)


def _on_message(client, userdata, msg):
    m = re.match(r"trustfarm/zone/(\d+)/telemetry", msg.topic)
    if not m:
        return
    try:
        data = json.loads(msg.payload)
        with SessionLocal() as db:
            process_reading(db, int(m.group(1)), data)
    except Exception:
        log.exception("Failed to process telemetry")


def start():
    c = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    c.username_pw_set(settings.mqtt_user, settings.mqtt_password)
    c.on_connect = _on_connect
    c.on_message = _on_message
    c.connect_async(settings.mqtt_host, settings.mqtt_port, keepalive=60)
    c.loop_start()
    return c
