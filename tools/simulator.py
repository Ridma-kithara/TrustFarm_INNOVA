"""Publishes fake telemetry over MQTT - use it to demo without hardware.

  pip install paho-mqtt
  python simulator.py --host localhost --user backend --password <pw> --zone 1
Type a fault mode while it runs: n=normal, s=stuck, j=spike, d=drift, b=low battery, q=quit
"""
import argparse, json, math, random, threading, time
import paho.mqtt.client as mqtt

mode = {"v": "n"}


def reader():
    while True:
        k = input().strip().lower()
        if k:
            mode["v"] = k[0]


ap = argparse.ArgumentParser()
ap.add_argument("--host", default="localhost")
ap.add_argument("--port", type=int, default=1883)
ap.add_argument("--user", default="backend")
ap.add_argument("--password", default="")
ap.add_argument("--zone", type=int, default=1)
ap.add_argument("--interval", type=float, default=5.0, help="seconds between messages")
a = ap.parse_args()

c = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
c.username_pw_set(a.user, a.password)
c.connect(a.host, a.port)
c.loop_start()
threading.Thread(target=reader, daemon=True).start()

soil, soc, t0, stuck_val, drift = 38.0, 70.0, time.time(), None, 0.0
while mode["v"] != "q":
    soil = max(8, soil - 0.15 + (6 if soil < 24 else 0) * random.random() * 0.3)
    s1 = soil + random.gauss(0, .3)
    s2 = soil + 1 + random.gauss(0, .3)
    m = mode["v"]
    if m == "s":
        stuck_val = stuck_val or s2
        s2 = stuck_val
    elif m == "j":
        s2 += 35
    elif m == "d":
        drift += 1.5
        s2 += drift
    else:
        stuck_val, drift = None, 0.0
    gen = max(0, 80 * math.sin((time.time() - t0) / 60)) if m != "b" else 0
    load = 12 + random.random() * 2
    soc = 12 if m == "b" else min(100, max(5, soc + (gen - load) * 0.002))
    msg = {"ts": time.time(), "soil1": round(s1, 2), "soil2": round(s2, 2),
           "temp": round(28 + random.gauss(0, .5), 1), "hum": round(68 + random.gauss(0, 2), 1),
           "rain": 0.0, "flow": 0.0, "batt_v": round(11.5 + soc / 100 * 1.5, 2),
           "batt_soc": round(soc, 1), "gen_w": round(gen, 1), "load_w": round(load, 1)}
    c.publish(f"trustfarm/zone/{a.zone}/telemetry", json.dumps(msg), qos=1)
    print(m, msg)
    time.sleep(a.interval)
