async function request(path, options = {}) {
  const res = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!res.ok) {
    let detail = res.statusText;
    try {
      const body = await res.json();
      detail = typeof body.detail === "string" ? body.detail : JSON.stringify(body.detail);
    } catch {
      /* not json */
    }
    throw new Error(`${res.status}: ${detail}`);
  }
  return res.status === 204 ? null : res.json();
}

export const api = {
  info: () => request("/api/info"),
  stats: () => request("/api/stats"),
  list: (params) => request("/api/items?" + new URLSearchParams(params)),
  create: (item) => request("/api/items", { method: "POST", body: JSON.stringify(item) }),
  update: (id, changes) => request(`/api/items/${id}`, { method: "PUT", body: JSON.stringify(changes) }),
  remove: (id) => request(`/api/items/${id}`, { method: "DELETE" }),
};
