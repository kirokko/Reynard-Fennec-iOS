// SPDX-License-Identifier: GPL-3.0-or-later
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { isUpstreamReady } from '../ports/ublock-webkit/readiness.mjs';

test('uBO readiness rejects upstream placeholder and unfinished async startup', () => {
    assert.equal(isUpstreamReady({ readyToFilter: true, supportStats: { allReadyAfter: '?' } }), false);
    assert.equal(isUpstreamReady({ readyToFilter: true }), false);
    assert.equal(isUpstreamReady({ readyToFilter: false, supportStats: { allReadyAfter: '5 ms' } }), false);
});
test('uBO readiness requires a real completion time and no observed errors', () => {
    const ubo = { readyToFilter: true, supportStats: { allReadyAfter: '15 ms' } };
    assert.equal(isUpstreamReady(ubo), true);
    assert.equal(isUpstreamReady(ubo, ['startup failed']), false);
    ubo.supportStats.allReadyAfter = '20 ms (selfie)';
    assert.equal(isUpstreamReady(ubo), true);
});
test('cooperative idle fallback executes and cancels actual scheduled tasks', async () => {
    const sandbox = { performance, setTimeout, clearTimeout };
    sandbox.self = sandbox;
    vm.runInNewContext(fs.readFileSync(new URL('../ports/ublock-webkit/scheduling.js', import.meta.url), 'utf8'), sandbox);
    let cancelledRan = false;
    const id = sandbox.requestIdleCallback(() => { cancelledRan = true; });
    sandbox.cancelIdleCallback(id);
    const budget = await new Promise(resolve => sandbox.requestIdleCallback(deadline => resolve(deadline.timeRemaining())));
    assert(budget >= 0 && budget <= 5);
    assert.equal(cancelledRan, false);
});
