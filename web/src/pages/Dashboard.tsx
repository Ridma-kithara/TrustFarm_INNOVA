import { useEffect, useState } from "react";
import { Alert, api, Point, Status, Zone } from "../api";
import Charts from "../components/Charts";
import TrustBadge from "../components/TrustBadge";

export default function Dashboard() {
  const [zones, setZones] = useState<Zone[]>([]);
  const [zoneId, setZoneId] = useState<number | null>(null);
  const [status, setStatus] = useState<Status | null>(null);
  const [points, setPoints] = useState<Point[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);

  useEffect(() => { api.zones().then((z) => { setZones(z); if (z.length) setZoneId(z[0].id); }); }, []);

  useEffect(() => {
    if (zoneId === null) return;
    const load = () => {
      api.status(zoneId).then(setStatus);
      api.readings(zoneId, 24).then(setPoints);
      api.alerts().then(setAlerts);
    };
    load();
    const t = setInterval(load, 15000);
    return () => clearInterval(t);
  }, [zoneId]);

  const r = status?.reading, rec = status?.recommendation, en = status?.energy;

  return (
    <div>
      <div className="row">
        <select value={zoneId ?? ""} onChange={(e) => setZoneId(Number(e.target.value))}>
          {zones.map((z) => <option key={z.id} value={z.id}>{z.farm} – {z.name}</option>)}
        </select>
        <TrustBadge level={status?.trust?.level} score={status?.trust?.score} />
      </div>

      <div className={`card advice ${status?.trust?.level ?? ""}`}>
        <h2>{rec?.advice ?? "Waiting for data…"}</h2>
        <p>{rec?.reason}</p>
        {status?.trust?.flags.length ? (
          <ul>{status.trust.flags.map((f, i) => <li key={i}>{f.message}</li>)}</ul>
        ) : null}
      </div>

      <div className="grid">
        <div className="card"><h3>Soil moisture</h3><p className="big">{r ? ((r.soil1 + r.soil2) / 2).toFixed(1) : "–"}%</p>
          <p className="muted">Forecast (3 h): {rec?.forecast_soil ?? "–"}% · Need: {rec?.need ?? "–"}</p></div>
        <div className="card"><h3>Battery</h3><p className="big">{r?.batt_soc?.toFixed(0) ?? "–"}%</p>
          <p className="muted">{en?.mode} · {en?.message}</p></div>
        <div className="card"><h3>Generation</h3><p className="big">{r?.gen_w?.toFixed(0) ?? "–"} W</p>
          <p className="muted">Load {r?.load_w?.toFixed(0) ?? "–"} W</p></div>
        <div className="card"><h3>Weather</h3><p className="big">{r?.temp?.toFixed(1) ?? "–"}°C</p>
          <p className="muted">Humidity {r?.hum?.toFixed(0) ?? "–"}%</p></div>
      </div>

      <Charts points={points} />

      <div className="card">
        <h3>Alerts</h3>
        {alerts.length === 0 && <p className="muted">No alerts</p>}
        {alerts.slice(0, 10).map((a) => (
          <p key={a.id}><b className={a.severity}>{a.severity}</b> · {new Date(a.ts).toLocaleString()} · {a.message}</p>
        ))}
      </div>
    </div>
  );
}
