const BASE = import.meta.env.VITE_API_URL ?? "/api";

export type User = { id: number; email: string; name: string; role: "farmer" | "officer" | "admin"; farm_id: number | null };
export type Zone = { id: number; name: string; farm: string; crop: string | null };
export type Flag = { code: string; message: string };
export type Status = {
  reading: null | { ts: string; soil1: number; soil2: number; temp: number; hum: number; batt_soc: number; gen_w: number; load_w: number };
  trust: null | { level: "Green" | "Amber" | "Red"; score: number; flags: Flag[] };
  recommendation: null | { advice: string; reason: string; need: string | null; forecast_soil: number | null; irrigate: boolean };
  energy: null | { mode: string; irrigation_ok: boolean; message: string; surplus_w: number };
};
export type Point = { ts: string; soil1: number; soil2: number; temp: number; batt_soc: number; gen_w: number; load_w: number };
export type Alert = { id: number; zone_id: number; ts: string; severity: string; message: string };

let token: string | null = localStorage.getItem("tf_token");
export const setToken = (t: string | null) => {
  token = t;
  t ? localStorage.setItem("tf_token", t) : localStorage.removeItem("tf_token");
};
export const hasToken = () => !!token;

async function req<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const r = await fetch(BASE + path, {
    ...opts,
    headers: { "Content-Type": "application/json", ...(token ? { Authorization: `Bearer ${token}` } : {}) },
  });
  if (r.status === 401) { setToken(null); location.reload(); }
  if (!r.ok) throw new Error((await r.json().catch(() => ({}))).detail ?? r.statusText);
  return r.json();
}

export const api = {
  login: (email: string, password: string) =>
    req<{ token: string; user: User }>("/auth/login", { method: "POST", body: JSON.stringify({ email, password }) }),
  me: () => req<User>("/me"),
  zones: () => req<Zone[]>("/zones"),
  status: (id: number) => req<Status>(`/zones/${id}/status`),
  readings: (id: number, hours = 24) => req<Point[]>(`/zones/${id}/readings?hours=${hours}`),
  alerts: () => req<Alert[]>("/alerts"),
  officerZones: () => req<any[]>("/officer/zones"),
  users: () => req<User[]>("/admin/users"),
  createUser: (u: object) => req<User>("/admin/users", { method: "POST", body: JSON.stringify(u) }),
};
