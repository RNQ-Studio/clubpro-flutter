/** Verify real browser auth redirects, using fresh isolated profiles and wall time.
 * node tool/check_protected_deeplinks.mjs [https://ceo-pro.web.app]
 * Local Hosting emulator http://localhost:5055 is also supported.
 * Console/resource smoke remains a separate check in the release wrapper.
 */
import {spawn} from 'node:child_process';
import {mkdtemp, readFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import assert from 'node:assert/strict';

const origin = new URL(process.argv[2] ?? 'https://ceo-pro.web.app');
assert(['https://ceo-pro.web.app', 'http://localhost:5055', 'http://127.0.0.1:5055'].includes(origin.origin), 'Unexpected test origin');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const routes = ['/wallet', '/billing-notices', '/communities/1/training', '/communities/1/training/report'];

class DevTools {
  constructor(socket) {
    this.socket = socket;
    this.sequence = 0;
    this.pending = new Map();
    this.requests = [];
    socket.addEventListener('message', event => {
      const message = JSON.parse(event.data);
      if (message.method === 'Network.requestWillBeSent') {
        const url = message.params.request.url;
        if (/\/api\/v1\/(wallet(?:[/?]|$)|billing-notices(?:[/?]|$)|communities\/[^/]+\/training(?:[/?]|$))/.test(url)) this.requests.push(url);
      }
      if (message.id && this.pending.has(message.id)) {
        const pending = this.pending.get(message.id);
        this.pending.delete(message.id);
        clearTimeout(pending.timeout);
        message.error ? pending.reject(new Error(message.error.message)) : pending.resolve(message.result);
      }
    });
  }
  send(method, params = {}) {
    const id = ++this.sequence;
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => { this.pending.delete(id); reject(new Error(`DevTools timeout: ${method}`)); }, 10000);
      this.pending.set(id, {resolve, reject, timeout});
      this.socket.send(JSON.stringify({id, method, params}));
    });
  }
  async value(expression) {
    const result = await this.send('Runtime.evaluate', {expression, returnByValue: true});
    return result.result.value;
  }
}

let failures = 0;
for (const route of routes) {
  const profile = await mkdtemp(join(tmpdir(), 'clubpro-auth-smoke-'));
  const process = spawn(chrome, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'], {stdio: 'ignore'});
  let socket;
  try {
    const deadline = Date.now() + 30000;
    let port;
    while (!port && Date.now() < deadline) {
      try { port = Number((await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]); } catch { await delay(100); }
    }
    assert(port, 'Chrome did not expose its isolated DevTools port');
    const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    const target = targets.find(target => target.type === 'page');
    assert(target?.webSocketDebuggerUrl, 'No isolated browser target');
    socket = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => { socket.addEventListener('open', resolve, {once: true}); socket.addEventListener('error', reject, {once: true}); });
    const devTools = new DevTools(socket);
    await devTools.send('Network.enable');
    await devTools.send('Page.enable');
    await devTools.send('Page.navigate', {url: `${origin.origin}/#${route}`});
    let hash = '';
    while (Date.now() < deadline) {
      hash = await devTools.value('location.hash');
      if (hash.startsWith('#/login?')) break;
      await delay(200);
    }
    const returnTo = new URLSearchParams(hash.split('?')[1] ?? '').get('from');
    const passed = hash.startsWith('#/login?') && returnTo === route && devTools.requests.length === 0;
    console.log(JSON.stringify({origin: origin.origin, route, hash, return_to: returnTo, private_requests: devTools.requests.length, result: passed ? 'PASS' : 'FAIL'}));
    if (!passed) failures++;
  } catch (error) {
    failures++;
    console.log(JSON.stringify({origin: origin.origin, route, result: 'FAIL', error: String(error)}));
  } finally {
    socket?.close();
    process.kill('SIGTERM');
    await new Promise(resolve => { if (process.exitCode !== null) resolve(); else { process.once('exit', resolve); setTimeout(resolve, 2000); } });
    await rm(profile, {recursive: true, force: true, maxRetries: 5, retryDelay: 100});
  }
}
if (failures) process.exitCode = 1;
