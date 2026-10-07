// Kept in a separate file so the Content-Security-Policy can forbid inline scripts.
const colours = ["#cf222e", "#e16f24", "#d4a72c", "#2da44e", "#1a7f37"];

async function check(password) {
  const resp = await fetch("/api/strength", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ password }),
  });
  const data = await resp.json();
  const bar = document.getElementById("bar");
  const list = document.getElementById("feedback");
  list.replaceChildren();
  if (!resp.ok) {
    document.getElementById("label").textContent = data.error;
    bar.style.width = "0";
    return;
  }
  bar.style.width = `${(data.score + 1) * 20}%`;
  bar.style.background = colours[data.score];
  document.getElementById("label").textContent =
    `${data.label} - about ${data.entropy_bits} bits, ${data.length} characters`;
  for (const tip of data.feedback) {
    const li = document.createElement("li");
    li.textContent = tip; // textContent, never innerHTML
    list.appendChild(li);
  }
}

document.getElementById("check").addEventListener("submit", (e) => {
  e.preventDefault();
  check(document.getElementById("password").value);
});

document.getElementById("gen").addEventListener("click", async () => {
  const data = await (await fetch("/api/generate?length=20")).json();
  const input = document.getElementById("password");
  input.type = "text";
  input.value = data.password;
  check(data.password);
});
