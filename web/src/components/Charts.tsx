import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Point } from "../api";

function Chart({ title, data, lines, unit }: { title: string; data: any[]; lines: { key: string; name: string; color: string }[]; unit?: string }) {
  return (
    <div className="card">
      <h3>{title}</h3>
      <ResponsiveContainer width="100%" height={220}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="t" minTickGap={40} />
          <YAxis unit={unit} />
          <Tooltip />
          <Legend />
          {lines.map((l) => (
            <Line key={l.key} dataKey={l.key} name={l.name} stroke={l.color} dot={false} isAnimationActive={false} />
          ))}
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

export default function Charts({ points }: { points: Point[] }) {
  const data = points.map((p) => ({ ...p, t: new Date(p.ts).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) }));
  return (
    <div className="grid">
      <Chart title="Soil moisture" unit="%" data={data} lines={[
        { key: "soil1", name: "Sensor 1", color: "#2a7de1" }, { key: "soil2", name: "Sensor 2", color: "#e17a2a" }]} />
      <Chart title="Temperature" unit="°C" data={data} lines={[{ key: "temp", name: "Temp", color: "#d64545" }]} />
      <Chart title="Battery state of charge" unit="%" data={data} lines={[{ key: "batt_soc", name: "SoC", color: "#2e9e5b" }]} />
      <Chart title="Generation vs load" unit=" W" data={data} lines={[
        { key: "gen_w", name: "Generation", color: "#8a4fd6" }, { key: "load_w", name: "Load", color: "#666" }]} />
    </div>
  );
}
