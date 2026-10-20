CREATE TABLE farms (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  crop TEXT
);

CREATE TABLE zones (
  id SERIAL PRIMARY KEY,
  farm_id INT NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  name TEXT NOT NULL
);

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('farmer','officer','admin')),
  farm_id INT REFERENCES farms(id)
);

CREATE TABLE readings (
  id BIGSERIAL PRIMARY KEY,
  zone_id INT NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
  ts TIMESTAMPTZ NOT NULL,
  soil1 REAL, soil2 REAL, temp REAL, hum REAL, rain REAL, flow REAL,
  batt_v REAL, batt_soc REAL, gen_w REAL, load_w REAL
);
CREATE INDEX idx_readings_zone_ts ON readings (zone_id, ts DESC);

CREATE TABLE trust_results (
  id BIGSERIAL PRIMARY KEY,
  zone_id INT NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
  ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  level TEXT NOT NULL CHECK (level IN ('Green','Amber','Red')),
  score REAL NOT NULL,
  flags JSONB NOT NULL DEFAULT '[]'
);
CREATE INDEX idx_trust_zone_ts ON trust_results (zone_id, ts DESC);

CREATE TABLE recommendations (
  id BIGSERIAL PRIMARY KEY,
  zone_id INT NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
  ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  need TEXT,
  forecast_soil REAL,
  irrigate BOOLEAN NOT NULL DEFAULT FALSE,
  advice TEXT NOT NULL,
  reason TEXT
);
CREATE INDEX idx_rec_zone_ts ON recommendations (zone_id, ts DESC);

CREATE TABLE energy_records (
  id BIGSERIAL PRIMARY KEY,
  zone_id INT NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
  ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  gen_w REAL, load_w REAL, batt_soc REAL,
  mode TEXT NOT NULL,
  irrigation_ok BOOLEAN NOT NULL,
  message TEXT
);
CREATE INDEX idx_energy_zone_ts ON energy_records (zone_id, ts DESC);

CREATE TABLE alerts (
  id BIGSERIAL PRIMARY KEY,
  zone_id INT REFERENCES zones(id) ON DELETE CASCADE,
  ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  severity TEXT NOT NULL,
  message TEXT NOT NULL,
  acknowledged BOOLEAN NOT NULL DEFAULT FALSE
);

-- Demo data: one farm, two test zones
INSERT INTO farms (name, location, crop) VALUES ('Demo Farm', 'Pilot site', 'Tomato');
INSERT INTO zones (farm_id, name) VALUES (1, 'Zone A'), (1, 'Zone B');
