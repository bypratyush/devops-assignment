// ui-shot.mjs - screenshot a web UI with headless Chrome, driven over the
// Chrome DevTools Protocol (CDP) instead of the --screenshot flag.
//
// Why not plain `chrome --headless --screenshot`? The Argo CD UI keeps a
// streaming watch connection open, so --virtual-time-budget never finishes and
// Chrome hangs. Driving CDP lets us wait a fixed time and then capture, and also
// set the argocd.token session cookie so no anonymous access has to be enabled.
//
//   node ui-shot.mjs <url> <out.png> <width> <height> [waitMs] [cookieName=value]
import { spawn } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const [url, out, width = '1400', height = '800', waitMs = '6000', cookie] = process.argv.slice(2);
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 19222;
const profile = mkdtempSync(join(tmpdir(), 'ui-shot-'));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const chrome = spawn(CHROME, [
  '--headless=new', '--disable-gpu', '--hide-scrollbars', '--ignore-certificate-errors',
  `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, 'about:blank',
], { stdio: 'ignore' });

let target;
for (let i = 0; i < 50 && !target; i++) {
  await sleep(200);
  try {
    const list = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
    target = list.find((t) => t.type === 'page');
  } catch { /* chrome not up yet */ }
}
if (!target) { console.error('chrome did not start'); chrome.kill(); process.exit(1); }

const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
let id = 0;
const pending = new Map();
ws.addEventListener('message', (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
});
const send = (method, params = {}) => new Promise((resolve) => {
  const n = ++id; pending.set(n, resolve); ws.send(JSON.stringify({ id: n, method, params }));
});

await send('Emulation.setDeviceMetricsOverride', { width: +width, height: +height, deviceScaleFactor: 1, mobile: false });
if (cookie) {
  const [name, ...rest] = cookie.split('=');
  await send('Network.enable');
  await send('Network.setCookie', { name, value: rest.join('='), url: new URL(url).origin });
}
await send('Page.enable');
await send('Page.navigate', { url });
await sleep(+waitMs);
const shot = await send('Page.captureScreenshot', { format: 'png' });
writeFileSync(out, Buffer.from(shot.result.data, 'base64'));
console.log(`  ${out.split('/').slice(-2).join('/')}`);

ws.close();
chrome.kill();
await sleep(300);
rmSync(profile, { recursive: true, force: true });
