// SPDX-License-Identifier: GPL-3.0-or-later
// Unofficial research port of FULL uBO. Does not emulate missing browser APIs.
const status = {
    experimental: true, fullUBlockOriginVerified: false, errors: [],
    backend: 'full-uBO-compiler-to-native-WebKit-DNR', network: { stage: 'starting' },
    upstream: { stage: 'not-started', readyToFilter: false },
    warning: 'Prototype only. Original popup switches/dynamic rules do NOT yet control the DNR backend. No production release.',
};
const errorText = error => String(error) + (error?.stack ? '\n' + error.stack : '');
addEventListener('error', event => status.errors.push(errorText(event.error || event.message)));
addEventListener('unhandledrejection', event => status.errors.push(errorText(event.reason)));
browser.runtime.onMessage.addListener((message, sender) => {
    if (message?.reynardPort === 'status') return Promise.resolve(structuredClone(status));
    if (!sender.url?.startsWith('http://127.0.0.1:8765/port/')) return;
    if (message?.reynardPort === 'test-rule-update') return updateSelfTest();
    if (message?.reynardPort === 'test-transaction') {
        // Local synthetic diagnostic only; never accepts arbitrary rule data.
        return transactionSelfTest();
    }
});

let worker;
let nextId = 0;
const pending = new Map();
function compile(text) {
    if (!worker) {
        worker = new Worker(browser.runtime.getURL('port/compiler-worker.mjs'), { type: 'module' });
        worker.onmessage = ({ data }) => {
            const job = pending.get(data.id);
            if (!job) return;
            clearTimeout(job.timer); pending.delete(data.id);
            if (data.error) job.reject(new Error(data.error)); else job.resolve(data.result);
        };
        worker.onerror = event => {
            for (const job of pending.values()) { clearTimeout(job.timer); job.reject(new Error(event.message)); }
            pending.clear(); worker.terminate(); worker = undefined;
        };
    }
    const id = ++nextId;
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => { pending.delete(id); reject(new Error('Compiler worker timed out')); }, 15000);
        pending.set(id, { resolve, reject, timer }); worker.postMessage({ id, text });
    });
}
let syncQueue = Promise.resolve();
function scheduleSync() {
    syncQueue = syncQueue.then(async () => {
        const { 'user-filters': text = '' } = await browser.storage.local.get('user-filters');
        status.network.stage = 'compiling';
        const result = await compile(text);
        status.conversion = result.report;
        const api = browser.declarativeNetRequest;
        if (!api?.updateDynamicRules) throw new Error('Native DNR updateDynamicRules unavailable');
        const before = await api.getDynamicRules();
        // This context is isolated and owns its dynamic rules. Native API must
        // replace the set atomically: rejection must NOT first delete old rules.
        await api.updateDynamicRules({ removeRuleIds: before.map(rule => rule.id), addRules: result.rules });
        const installed = await api.getDynamicRules();
        // Compare canonical JSON recursively; object key order is not semantic.
        const canonical = value => JSON.stringify(value, (_, v) => v && !Array.isArray(v) && typeof v === 'object'
            ? Object.fromEntries(Object.entries(v).sort(([a], [b]) => a.localeCompare(b))) : v);
        if (canonical(installed.toSorted((a,b) => a.id-b.id)) !== canonical(result.rules.toSorted((a,b) => a.id-b.id))) {
            await api.updateDynamicRules({ removeRuleIds: installed.map(rule => rule.id), addRules: before });
            throw new Error('Native DNR readback differed; previous set restored');
        }
        status.network = { stage: 'installed', installedRuleCount: installed.length, atomicReadbackMatched: true };
    }).catch(error => { status.network.stage = 'failed'; status.network.error = errorText(error); });
    return syncQueue;
}
browser.storage.onChanged.addListener((changes, area) => {
    if (area === 'local' && Object.hasOwn(changes, 'user-filters')) scheduleSync();
});

let selfTest;
function transactionSelfTest() {
    if (selfTest) return selfTest;
    selfTest = syncQueue.then(async () => {
        const api = browser.declarativeNetRequest;
        const before = await api.getDynamicRules();
        let rejected = false;
        try {
            await api.updateDynamicRules({ removeRuleIds: before.map(rule => rule.id), addRules: [
                { id: -1, action: { type: 'block' }, condition: { urlFilter: '/never-installed/' } },
            ] });
        } catch (error) { rejected = true; }
        const after = await api.getDynamicRules();
        const unchanged = JSON.stringify(before.toSorted((a,b)=>a.id-b.id)) === JSON.stringify(after.toSorted((a,b)=>a.id-b.id));
        status.transaction = { rejected, oldRulesUnchanged: unchanged };
        if (!unchanged) {
            await api.updateDynamicRules({ removeRuleIds: after.map(rule=>rule.id), addRules: before });
            status.transaction.restored = true;
        }
        return status.transaction;
    }).catch(error => ({ error: errorText(error) }));
    return selfTest;
}

let updateTest;
function updateSelfTest() {
    if (updateTest) return updateTest;
    updateTest = (async () => {
        const old = await browser.storage.local.get('user-filters');
        await browser.storage.local.set({ 'user-filters': old['user-filters'] + '\n/port/new-rule.txt\n' });
        await scheduleSync();
        return { storageChangeApplied: status.network.stage === 'installed', network: structuredClone(status.network) };
    })().catch(error => ({ error: errorText(error) }));
    return updateTest;
}

async function start() {
    // Probe-only seed, in a fresh disposable context. NOT a production migration
    // and never called on a user's existing extension profile.
    const fixture = await (await fetch(browser.runtime.getURL('port/filters.txt'))).text();
    await browser.storage.local.set({ 'user-filters': fixture, selectedFilterLists: ['user-filters'], autoUpdate: false });
    await scheduleSync();
    status.upstream.stage = 'importing-original-start';
    try {
        const unboundGetURL = browser.runtime.getURL;
        status.nativeReceiver = { directURL: browser.runtime.getURL('') };
        try { status.nativeReceiver.unboundURL = unboundGetURL('') ?? 'undefined'; }
        catch (error) { status.nativeReceiver.unboundError = errorText(error); }
        await import('../js/vapi-common.js');
        // Truthful platform flavor, not a pretend Firefox/Chromium version.
        vAPI.webextFlavor.soup.add('safari');
        await import('../js/start.js');
        const { default: ubo } = await import('../js/background.js');
        status.upstream.stage = 'initializing';
        const deadline = Date.now() + 20000;
        const poll = () => {
            status.upstream.readyToFilter = ubo.readyToFilter === true;
            status.upstream.allReadyAfter = ubo.supportStats?.allReadyAfter || '';
            if (status.upstream.readyToFilter && status.upstream.allReadyAfter) { status.upstream.stage = 'ready'; return; }
            if (Date.now() >= deadline) { status.upstream.stage = 'initialization-timeout'; return; }
            setTimeout(poll, 100);
        };
        poll();
    } catch (error) { status.upstream.stage = 'failed'; status.upstream.error = errorText(error); }
}
start().catch(error => { status.errors.push(errorText(error)); status.network.stage = 'failed'; });
