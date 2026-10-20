import { useEffect, useState } from "react";
import { api, User } from "../api";

export default function Admin() {
  const [users, setUsers] = useState<User[]>([]);
  const [f, setF] = useState({ email: "", name: "", password: "", role: "farmer", farm_id: 1 });
  const [msg, setMsg] = useState("");
  const load = () => api.users().then(setUsers);
  useEffect(() => { load(); }, []);

  const create = async () => {
    try { await api.createUser(f); setMsg("User created"); load(); }
    catch (e: any) { setMsg(e.message); }
  };

  return (
    <div>
      <div className="card">
        <h3>Create user</h3>
        <input placeholder="Email" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} />
        <input placeholder="Name" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} />
        <input placeholder="Password" type="password" value={f.password} onChange={(e) => setF({ ...f, password: e.target.value })} />
        <select value={f.role} onChange={(e) => setF({ ...f, role: e.target.value })}>
          <option>farmer</option><option>officer</option><option>admin</option>
        </select>
        <input placeholder="Farm ID" type="number" value={f.farm_id} onChange={(e) => setF({ ...f, farm_id: Number(e.target.value) })} />
        <button onClick={create}>Create</button> <span className="muted">{msg}</span>
      </div>
      <div className="card">
        <h3>Users</h3>
        <table>
          <thead><tr><th>Email</th><th>Name</th><th>Role</th><th>Farm</th></tr></thead>
          <tbody>{users.map((u) => <tr key={u.id}><td>{u.email}</td><td>{u.name}</td><td>{u.role}</td><td>{u.farm_id ?? "–"}</td></tr>)}</tbody>
        </table>
      </div>
    </div>
  );
}
