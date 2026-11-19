// SPDX-License-Identifier: GPL-3.0-or-later
// Cooperative timer fallback, NOT a claim of native browser idle scheduling.
// Executes real work with a measured 5 ms task budget; never returns fake API
// success for network, permissions, injection, or extension lifecycle features.
(() => {
    if (typeof self.requestIdleCallback === 'function') return;
    let next = 0;
    const timers = new Map();
    self.requestIdleCallback = (callback, options) => {
        if (typeof callback !== 'function') throw new TypeError('Idle callback must be a function');
        const id = ++next;
        const requestedAt = performance.now();
        const timeout = Math.max(0, Number(options?.timeout) || 0);
        timers.set(id, setTimeout(() => {
            timers.delete(id);
            const start = performance.now();
            callback({
                didTimeout: start - requestedAt >= timeout,
                timeRemaining: () => Math.max(0, 5 - (performance.now() - start)),
            });
        }, 1));
        return id;
    };
    self.cancelIdleCallback = id => {
        if (!timers.has(id)) return;
        clearTimeout(timers.get(id)); timers.delete(id);
    };
})();
