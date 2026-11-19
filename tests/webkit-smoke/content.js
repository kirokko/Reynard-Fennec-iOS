// GPL-3.0. Failures are evidence, not simulated success.
(async () => {
    try {
        const result = await browser.runtime.sendMessage('reynard-probe');
        document.documentElement.setAttribute('data-extension-result', JSON.stringify(result));
    } catch (error) {
        document.documentElement.setAttribute('data-extension-result', JSON.stringify({error: String(error)}));
    }
})();
