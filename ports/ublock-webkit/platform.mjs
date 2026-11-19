// SPDX-License-Identifier: GPL-3.0-or-later
// Real platform adaptations, NOT fake implementations under browser.*.
export function installPlatform(vapi, status, synchronizeNetworkRules) {
    vapi.webKitPlatform = {
        listenForNavigationTargets(handler) {
            if (browser.webNavigation.onCreatedNavigationTarget?.addListener) {
                browser.webNavigation.onCreatedNavigationTarget.addListener(handler);
                status.navigationTargets = { source: 'native-webNavigation' };
                return;
            }
            if (!browser.tabs.onCreated?.addListener) throw new Error('No native tab creation event available');
            status.navigationTargets = {
                source: 'native-tabs.onCreated',
                limitation: 'Only known openerTabId is forwarded. Source frame attribution unavailable; frame-specific popup filtering is NOT verified/equivalent.',
            };
            browser.tabs.onCreated.addListener(tab => {
                if (!Number.isInteger(tab.openerTabId)) return;
                // Do NOT invent sourceFrameId=0: an iframe may be the opener.
                handler({ tabId: tab.id, sourceTabId: tab.openerTabId, url: tab.url || '' });
            });
        },
        handlerBehaviorChanged() {
            status.nativeRebuildRequests = (status.nativeRebuildRequests || 0) + 1;
            if (typeof browser.webRequest.handlerBehaviorChanged === 'function') browser.webRequest.handlerBehaviorChanged();
            // Actual rule recompilation/atomic install, not a successful no-op.
            // Still only user-filters: dynamic firewall/whitelist/list bridge
            // remains explicitly unsupported, not silently treated as working.
            return synchronizeNetworkRules();
        },
    };
}
