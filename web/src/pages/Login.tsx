import { useState } from "react";
import { api, setToken } from "../api";

export default function Login({ onDone }: { onDone: () => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");

  const submit = async () => {
    try {
      const r = await api.login(email, password);
      setToken(r.token);
      onDone();
    } catch (e: any) { setErr(e.message); }
  };

  return (
    <div className="login card">
      <h2>TrustFarm</h2>
      <p className="muted">Trust before advice.</p>
      <input placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
      <input placeholder="Password" type="password" value={password}
             onChange={(e) => setPassword(e.target.value)} onKeyDown={(e) => e.key === "Enter" && submit()} />
      {err && <p className="err">{err}</p>}
      <button onClick={submit}>Sign in</button>
    </div>
  );
}
