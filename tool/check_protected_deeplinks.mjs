/** Verify real browser auth redirects, using fresh isolated profiles and wall time.
 * node tool/check_protected_deeplinks.mjs [https://ceo-pro.web.app] [route ...]
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
const routes = ['/wallet', '/billing-notices', '/communities/1/training', '/communities/1/training/report', '/wallet/bank-account', '/wallet/payouts', '/wallet/payouts/new', '/wallet/payouts/synthetic-id', '/wallet/payouts?manage=1&community=1', '/wallet/transfers', '/wallet/transfers/new', '/wallet/payouts/synthetic-id/parts/synthetic-part/proof', '/wallet/payouts/synthetic-id/parts/synthetic-part/fragments/synthetic-fragment', '/wallet/payouts?manage=1', '/marketplace/my-products', '/marketplace/my-products/new', '/marketplace/my-products/synthetic-id/edit', '/marketplace/checkout/synthetic-id', '/marketplace/orders', '/marketplace/orders/synthetic-id'];
const selectedRoutes = process.argv.length > 3 ? process.argv.slice(3) : routes;
assert(selectedRoutes.every(route => routes.includes(route)), 'Unexpected protected test route');

function loginReturn(location) {
  if (typeof location !== 'string') return null;
  try {
    const route = new URL(location.replace(/^#/, ''), origin.origin);
    if (route.pathname !== '/login') return null;
    const value = route.searchParams.get('from');
    if (value?.startsWith('v1.')) {
      const token = value.slice(3);
      if (!/^[A-Za-z0-9_-]+$/.test(token)) return null;
      return new TextDecoder('utf-8', {fatal: true}).decode(Buffer.from(token, 'base64url'));
    }
    return value;
  } catch {
    return null;
  }
}

class DevTools {
  constructor(socket) {
    this.socket = socket;
    this.sequence = 0;
    this.pending = new Map();
    this.requests = [];
    this.loads = 0;
    socket.addEventListener('message', event => {
      const message = JSON.parse(event.data);
      if (message.method === 'Page.loadEventFired') this.loads++;
      if (message.method === 'Network.requestWillBeSent') {
        const url = message.params.request.url;
        if (/\/api\/v1\/(marketplace(?:[/?]|$)|bank-accounts(?:[/?]|$)|payouts(?:[/?]|$)|payout-parts(?:[/?]|$)|payout-reconciliation(?:[/?]|$)|transfers(?:[/?]|$)|wallet(?:[/?]|$)|billing-notices(?:[/?]|$)|communities\/[^/]+\/(?:training|payout-reconciliation)(?:[/?]|$))/.test(url)) this.requests.push(url);
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

async function loginSnapshot(devTools, deadline, previousDocument = null) {
  let snapshot;
  while (Date.now() < deadline) {
    snapshot = await devTools.value(`({hash: location.hash, state_location: history.state?.state?.location ?? history.state?.location ?? null, route_writes: window.__clubproRouteWrites ?? 0, document_id: window.__clubproDocumentId ?? null, app_mounted: !!document.querySelector('flutter-view')})`);
    if (snapshot.hash.startsWith('#/login?') && snapshot.state_location?.startsWith('/login?') && snapshot.route_writes > 0 && snapshot.document_id && snapshot.document_id !== previousDocument && snapshot.app_mounted) {
      // A fresh document must mount Flutter and publish history before inspecting
      // its serialized state. The old hash alone survives a browser reload.
      await delay(250);
      snapshot = await devTools.value(`({hash: location.hash, state_location: history.state?.state?.location ?? history.state?.location ?? null, route_writes: window.__clubproRouteWrites ?? 0, document_id: window.__clubproDocumentId ?? null, app_mounted: !!document.querySelector('flutter-view')})`);
      return {...snapshot, return_to: loginReturn(snapshot.hash), state_return_to: loginReturn(snapshot.state_location)};
    }
    await delay(100);
  }
  throw new Error(`Fresh login page did not settle: ${JSON.stringify(snapshot)}`);
}

let failures = 0;
for (const route of selectedRoutes) {
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
    await devTools.send('Page.addScriptToEvaluateOnNewDocument', {source: `window.__clubproDocumentId = Math.random().toString(36).slice(2); window.__clubproRouteWrites = 0; for (const name of ['pushState', 'replaceState']) { const original = history[name]; history[name] = function(...args) { window.__clubproRouteWrites++; return original.apply(this, args); }; }`});
    await devTools.send('Page.navigate', {url: `${origin.origin}/#${route}`});
    const initial = await loginSnapshot(devTools, Date.now() + 30000);
    const priorLoads = devTools.loads;
    await devTools.send('Page.reload', {ignoreCache: true});
    const reloadDeadline = Date.now() + 30000;
    while (devTools.loads <= priorLoads && Date.now() < reloadDeadline) {
      await delay(100);
    }
    assert(devTools.loads > priorLoads, 'Browser reload did not finish loading a fresh document');
    const afterReload = await loginSnapshot(devTools, reloadDeadline, initial.document_id);
    const passed = initial.return_to === route && initial.state_return_to === route && afterReload.return_to === route && afterReload.state_return_to === route && devTools.requests.length === 0;
    console.log(JSON.stringify({origin: origin.origin, route, hash: initial.hash, return_to: initial.return_to, state_return_to: initial.state_return_to, after_reload: afterReload, private_requests: devTools.requests.length, result: passed ? 'PASS' : 'FAIL'}));
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
