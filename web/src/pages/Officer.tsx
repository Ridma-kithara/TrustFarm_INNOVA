import { useEffect, useState } from "react";
import { api } from "../api";
import TrustBadge from "../components/TrustBadge";

export default function Officer() {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => { api.officerZones().then(setRows); }, []);
  return (
    <div className="card">
      <h3>Zones & sensor health</h3>
      <table>
        <thead><tr><th>Zone</th><th>Last seen</th><th>Trust</th><th>Battery</th><th>Issues</th></tr></thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.zone_id}>
              <td>{r.zone}</td>
              <td>{r.last_seen ? new Date(r.last_seen).toLocaleString() : "never"}</td>
              <td><TrustBadge level={r.trust} score={r.score} /></td>
              <td>{r.batt_soc?.toFixed(0) ?? "–"}%</td>
              <td>{r.flags.map((f: any) => f.message).join("; ")}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
