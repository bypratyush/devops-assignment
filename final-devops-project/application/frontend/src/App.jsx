import { useCallback, useEffect, useState } from "react";
import { api } from "./api.js";

const CATEGORIES = ["electronics", "id-card", "books", "clothing", "keys", "bottle", "other"];
const EMPTY = { kind: "lost", title: "", description: "", category: "other", location: "", contact: "" };

function StatCard({ label, value, tone }) {
  return (
    <div className={`stat ${tone}`}>
      <span className="stat-value">{value}</span>
      <span className="stat-label">{label}</span>
    </div>
  );
}

function ItemCard({ item, onStatus, onDelete }) {
  const when = new Date(item.created_at).toLocaleString();
  return (
    <li className={`item ${item.kind} ${item.status}`}>
      <div className="item-head">
        <span className={`badge ${item.kind}`}>{item.kind}</span>
        <h3>{item.title}</h3>
        <span className={`status ${item.status}`}>{item.status}</span>
      </div>
      {item.description && <p className="desc">{item.description}</p>}
      <p className="meta">
        <b>{item.category}</b> · {item.location} · {item.contact}
      </p>
      <p className="meta small">reported {when}</p>
      <div className="actions">
        {item.status === "open" && <button onClick={() => onStatus(item, "claimed")}>Mark claimed</button>}
        {item.status !== "closed" && <button onClick={() => onStatus(item, "closed")}>Close</button>}
        {item.status !== "open" && <button onClick={() => onStatus(item, "open")}>Re-open</button>}
        <button className="danger" onClick={() => onDelete(item)}>Delete</button>
      </div>
    </li>
  );
}

export default function App() {
  const [info, setInfo] = useState(null);
  const [stats, setStats] = useState(null);
  const [items, setItems] = useState([]);
  const [filter, setFilter] = useState({ kind: "", status: "", q: "" });
  const [form, setForm] = useState(EMPTY);
  const [error, setError] = useState("");

  const refresh = useCallback(async () => {
    try {
      const params = Object.fromEntries(Object.entries(filter).filter(([, v]) => v));
      const [list, s] = await Promise.all([api.list(params), api.stats()]);
      setItems(list);
      setStats(s);
      setError("");
    } catch (e) {
      setError(`Could not reach the API (${e.message})`);
    }
  }, [filter]);

  useEffect(() => {
    api.info().then(setInfo).catch(() => setInfo(null));
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  async function submit(e) {
    e.preventDefault();
    try {
      await api.create(form);
      setForm(EMPTY);
      refresh();
    } catch (err) {
      setError(err.message);
    }
  }

  async function changeStatus(item, status) {
    await api.update(item.id, { status });
    refresh();
  }

  async function remove(item) {
    await api.remove(item.id);
    refresh();
  }

  const set = (field) => (e) => setForm({ ...form, [field]: e.target.value });

  return (
    <div className="page">
      <header>
        <div>
          <h1>Campus Lost &amp; Found</h1>
          <p className="sub">Report something you lost, or something you found, at the help desk.</p>
        </div>
        {info && (
          <div className="env">
            <span>{info.environment}</span>
            <span>{/^\d/.test(info.version) ? `v${info.version}` : info.version}</span>
            <span title="pod that served /api/info">{info.pod}</span>
          </div>
        )}
      </header>

      {info?.notice && <div className="notice">{info.notice}</div>}
      {error && <div className="error">{error}</div>}

      {stats && (
        <section className="stats">
          <StatCard label="lost, still open" value={stats.lost_open} tone="lost" />
          <StatCard label="found, waiting for owner" value={stats.found_open} tone="found" />
          <StatCard label="claimed" value={stats.claimed} tone="claimed" />
          <StatCard label="closed" value={stats.closed} tone="closed" />
        </section>
      )}

      <main>
        <form className="card" onSubmit={submit}>
          <h2>Report an item</h2>
          <div className="kind-toggle">
            {["lost", "found"].map((k) => (
              <label key={k} className={form.kind === k ? "on" : ""}>
                <input type="radio" name="kind" value={k} checked={form.kind === k} onChange={set("kind")} />I{" "}
                {k} something
              </label>
            ))}
          </div>
          <input placeholder="What is it? e.g. Black leather wallet" value={form.title} onChange={set("title")} required minLength={3} />
          <textarea placeholder="Details (colour, brand, anything that proves it is yours)" value={form.description} onChange={set("description")} rows={3} />
          <select value={form.category} onChange={set("category")}>
            {CATEGORIES.map((c) => (
              <option key={c}>{c}</option>
            ))}
          </select>
          <input placeholder="Where? e.g. Library 2nd floor" value={form.location} onChange={set("location")} required minLength={2} />
          <input placeholder="Contact (email or phone)" value={form.contact} onChange={set("contact")} required minLength={3} />
          <button type="submit">Submit report</button>
        </form>

        <section className="list">
          <div className="filters">
            <input placeholder="Search title or place" value={filter.q} onChange={(e) => setFilter({ ...filter, q: e.target.value })} />
            <select value={filter.kind} onChange={(e) => setFilter({ ...filter, kind: e.target.value })}>
              <option value="">lost + found</option>
              <option value="lost">lost only</option>
              <option value="found">found only</option>
            </select>
            <select value={filter.status} onChange={(e) => setFilter({ ...filter, status: e.target.value })}>
              <option value="">any status</option>
              <option value="open">open</option>
              <option value="claimed">claimed</option>
              <option value="closed">closed</option>
            </select>
          </div>
          {items.length === 0 ? (
            <p className="empty">Nothing reported yet.</p>
          ) : (
            <ul>
              {items.map((item) => (
                <ItemCard key={item.id} item={item} onStatus={changeStatus} onDelete={remove} />
              ))}
            </ul>
          )}
        </section>
      </main>
      <footer>Final DevOps project · Pratyush Mohanty (24BCS10238)</footer>
    </div>
  );
}
