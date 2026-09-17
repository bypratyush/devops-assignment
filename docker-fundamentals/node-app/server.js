const http = require('http');
const os = require('os');
const PORT = process.env.PORT || 3000;
const NAME = process.env.APP_NAME || 'node-app';

http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    app: NAME,
    hostname: os.hostname(),
    platform: `${os.platform()}/${os.arch()}`,
    node: process.version,
    uptime_s: Math.round(process.uptime()),
    path: req.url,
  }, null, 2));
}).listen(PORT, () => console.log(`${NAME} listening on :${PORT}`));
