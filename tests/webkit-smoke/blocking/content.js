// GPL-3.0. Bridge diagnostics only; fetches are initiated in the webpage world.
async function readCapabilities(message) {
    try {
        const value = await browser.runtime.sendMessage(message);
        document.documentElement.setAttribute('data-blocking-capabilities', JSON.stringify(value));
    } catch (error) {
        document.documentElement.setAttribute('data-blocking-capabilities', JSON.stringify({ error: String(error) }));
    }
}
window.addEventListener('message', event => {
    if (event.source === window && event.data === 'reynard-blocking-refresh') readCapabilities('after-fetch');
});
readCapabilities('before-fetch');
