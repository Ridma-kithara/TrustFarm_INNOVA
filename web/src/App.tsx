import { useEffect, useState } from "react";
import { api, hasToken, setToken, User } from "./api";
import Admin from "./pages/Admin";
import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";
import Officer from "./pages/Officer";

export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [tab, setTab] = useState("dashboard");

  const loadUser = () => api.me().then(setUser).catch(() => setToken(null));
  useEffect(() => { if (hasToken()) loadUser(); }, []);

  if (!user) return <Login onDone={loadUser} />;

  const tabs = [["dashboard", "Farm"]];
  if (user.role !== "farmer") tabs.push(["officer", "Officer"]);
  if (user.role === "admin") tabs.push(["admin", "Admin"]);

  return (
    <div className="app">
      <header>
        <b>🌱 TrustFarm</b>
        <nav>{tabs.map(([k, l]) => <button key={k} className={tab === k ? "on" : ""} onClick={() => setTab(k)}>{l}</button>)}</nav>
        <span className="muted">{user.name} ({user.role})</span>
        <button onClick={() => { setToken(null); location.reload(); }}>Log out</button>
      </header>
      <main>
        {tab === "dashboard" && <Dashboard />}
        {tab === "officer" && <Officer />}
        {tab === "admin" && <Admin />}
      </main>
    </div>
  );
}
