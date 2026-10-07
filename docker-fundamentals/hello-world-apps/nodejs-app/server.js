// Hello World - Node.js (Express) in a container.
const express = require("express");
const os = require("os");

const PORT = Number(process.env.PORT) || 3000;
const app = express();

app.get("/", (req, res) => {
  res.send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Hello World - Node.js</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #f3f7f2; color: #1d2b1f; margin: 0; }
    main { max-width: 640px; margin: 60px auto; padding: 32px 40px; background: #fff;
           border-top: 6px solid #3c873a; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,.08); }
    h1 { margin: 0 0 8px; color: #3c873a; }
    td { padding: 4px 16px 4px 0; } td:first-child { color: #667; }
    footer { margin-top: 24px; font-size: 14px; color: #556; }
  </style>
</head>
<body>
  <main>
    <h1>Hello World from Node.js</h1>
    <p>An Express server running inside a Docker container.</p>
    <table>
      <tr><td>Runtime</td><td>Node ${process.version}</td></tr>
      <tr><td>Container hostname</td><td>${os.hostname()}</td></tr>
      <tr><td>Platform</td><td>${os.platform()}/${os.arch()}</td></tr>
    </table>
    <footer>Built by Pratyush Mohanty (Roll No. 24BCS10238)</footer>
  </main>
</body>
</html>`);
});

app.get("/healthz", (req, res) => res.json({ status: "ok" }));

const server = app.listen(PORT, () => console.log(`nodejs-app listening on :${PORT}`));

// docker stop sends SIGTERM. Without this handler Node ignores it as PID 1,
// Docker waits 10s and then SIGKILLs the process (exit 137).
process.on("SIGTERM", () => {
  console.log("SIGTERM received, closing server");
  server.close(() => process.exit(0));
});
