// GPL-3.0. Exercises actual browser.* message and storage APIs.
browser.runtime.onMessage.addListener(async message => {
    if (message !== 'reynard-probe') throw new Error('Unexpected message');
    await browser.storage.local.set({ probe: 'native-roundtrip' });
    const { probe } = await browser.storage.local.get('probe');
    return { probe, runtime: typeof browser.runtime.getURL === 'function' };
});
