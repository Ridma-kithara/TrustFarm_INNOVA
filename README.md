# TrustFarm – SmartCrop AI (INNOVA 2026)

Sense → Verify → Predict → Explain → Advise → Generate → Store → Optimize

```
ESP32 sensors ──MQTT──> Mosquitto ──> backend (FastAPI) ──HTTP──> ai_service (FastAPI + scikit-learn)
                                          │  PostgreSQL
                                          └── REST API ──> React web (port 3000) + Flutter app
```

| Folder | What | Tech |
|---|---|---|
| `ai_service/` | Trust Engine, forecast, irrigation need, explanation, training | Python, FastAPI, scikit-learn |
| `backend/` | Auth/roles, MQTT ingest, pipeline, energy management, REST | Python, FastAPI, SQLAlchemy |
| `db/init.sql` | Schema + demo farm/zones | PostgreSQL |
| `firmware/esp32/` | Sensor node with store-and-forward | C++ / PlatformIO |
| `web/` | Farmer / Officer / Admin dashboards | React + TypeScript + Recharts |
| `mobile/` | Android + iOS app | Flutter + fl_chart |
| `tools/simulator.py` | Fake sensor node with fault injection | Python |
| `mosquitto/` | MQTT broker config | Mosquitto |

## Live demos & links

| What | Link |
|---|---|
| Interactive preview (GitHub Pages) | https://ridma-kithara.github.io/TrustFarm_INNOVA/ |
| 3D hardware circuit (GitHub Pages) | https://ridma-kithara.github.io/TrustFarm_INNOVA/circuit.html |
| Official presentation video (OneDrive) | https://1drv.ms/v/c/4f62f12765f45059/IQA4KfAQ7rAjQoXclp-mmFNaASPvikbJtULQX-Zha3JyRFQ?e=g3esIL |
| Source repository | https://github.com/Ridma-kithara/TrustFarm_INNOVA |
| Flutter mobile app | [mobile/](mobile/) |
| Backend API | [backend/](backend/) |
| AI / trust engine | [ai_service/](ai_service/) |
| React dashboards | [web/](web/) |
| ESP32 firmware | [firmware/esp32/](firmware/esp32/) |
| Docs & media | [docs/](docs/) |

## Run (Docker)

```bash
cp .env.example .env              # edit the secrets
# 1. MQTT users (broker rejects anonymous clients)
touch mosquitto/passwd
docker run --rm -v "$PWD/mosquitto:/m" eclipse-mosquitto:2 mosquitto_passwd -b /m/passwd backend  <MQTT_PASSWORD from .env>
docker run --rm -v "$PWD/mosquitto:/m" eclipse-mosquitto:2 mosquitto_passwd -b /m/passwd esp32-zone1 <device-password>
# 2. Train models (synthetic data for the demo)
cd ai_service && pip install -r requirements.txt && python train.py && cd ..
# 3. Start everything
docker compose up --build
```

- Web: http://localhost:3000  (login with ADMIN_EMAIL / ADMIN_PASSWORD from `.env`)
- API docs: http://localhost:8000/docs
- Demo without hardware: `python tools/simulator.py --password <MQTT_PASSWORD> --zone 1`
  then type `s` (stuck sensor), `j` (spike), `d` (drift), `b` (low battery), `n` (normal), `q` (quit).
  Watch Trust go Green → Red and the irrigation advice pause — that is the INNOVA demo story.
- Create a farmer: web → Admin → Create user (role `farmer`, farm ID 1).

## Mobile
```bash
cd mobile && flutter create . && flutter pub get
flutter run --dart-define=API_URL=http://<PC-LAN-IP>:8000
```
(`flutter create .` generates the android/ios folders; the `lib/` and `pubspec.yaml` here are kept.)
Allow cleartext HTTP on Android for local testing, or put the API behind HTTPS (recommended).

## Firmware
Edit `firmware/esp32/src/config.h` (WiFi, MQTT, ZONE_ID, calibration), then `pio run -t upload`.
Wiring: soil sensors GPIO34/35, rain GPIO32, flow meter GPIO27, DHT22 GPIO4, two INA219 on I²C
(0x40 generation/charger side, 0x41 load side).

## Honest limitations (read before presenting)
- **Models are trained on synthetic data** by default. Metrics printed by `train.py` are therefore
  *not* real-world results. Retrain with AquaIntel / AgriField-Manipur (needs IEEE DataPort access)
  or your pilot data: `python train.py --csv data.csv` (columns `ts,soil1,soil2,temp,hum,rain`).
- Soil % thresholds (`ai_service/app/features.py`) are placeholders – set per crop.
- Explanations are rule/feature-based text; SHAP is not wired in (optional extension).
- Push notifications are **not** implemented (needs Firebase setup); alerts show in-app.
- The system only *recommends* irrigation; it never switches the pump.
- Battery SoC from voltage is a rough estimate; use a BMS/fuel-gauge for the real battery.
- **Biogas digester, gas cleaning, generator, charge controller and wiring are physical hardware** –
  this code only monitors them. Build them with qualified supervision (ventilation, pressure relief,
  gas detection, fusing, earthing) as your proposal's safety note says.
- Security for production: change all secrets, use TLS for MQTT/HTTP, restrict CORS, per-device MQTT credentials.
