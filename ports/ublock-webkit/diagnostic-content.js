// SPDX-License-Identifier: GPL-3.0-or-later
// CI localhost only. Does NOT hide elements or inject the tested scriptlet.
let transactionDone = false;
async function poll() {
    try {
        const status = await browser.runtime.sendMessage({ reynardPort: 'status' });
        document.documentElement.setAttribute('data-ubo-port-status', JSON.stringify(status));
        if (!transactionDone && status.network?.stage === 'installed') {
            transactionDone = true;
            const result = await browser.runtime.sendMessage({ reynardPort: 'test-transaction' });
            document.documentElement.setAttribute('data-ubo-port-transaction', JSON.stringify(result));
        }
    } catch (error) {
        document.documentElement.setAttribute('data-ubo-port-bridge-error', String(error));
    }
    setTimeout(poll, 200);
}
window.addEventListener('message', async event => {
    if (event.source !== window || event.data !== 'reynard-port-update') return;
    try {
        const result = await browser.runtime.sendMessage({ reynardPort: 'test-rule-update' });
        document.documentElement.setAttribute('data-ubo-port-update', JSON.stringify(result));
    } catch (error) {
        document.documentElement.setAttribute('data-ubo-port-update', JSON.stringify({ error: String(error) }));
    }
});
poll();
