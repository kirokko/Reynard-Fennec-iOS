// GPL-3.0. Real cancellation prerequisite, not a uBlock implementation.
let blockedRequestsObserved = 0;
let registrationError = null;
try {
    browser.webRequest.onBeforeRequest.addListener(details => {
        if (new URL(details.url).pathname === '/blocked.txt') {
            blockedRequestsObserved++;
            return { cancel: true };
        }
        return {};
    }, { urls: ['http://127.0.0.1/*'] }, ['blocking']);
} catch (error) {
    registrationError = String(error);
}
browser.runtime.onMessage.addListener(message => Promise.resolve({
    afterFetch: message === 'after-fetch', blockedRequestsObserved, registrationError,
    filterResponseData: typeof browser.webRequest?.filterResponseData,
    dnsResolve: typeof browser.dns?.resolve,
    publicSuffix: typeof browser.publicSuffix,
}));
