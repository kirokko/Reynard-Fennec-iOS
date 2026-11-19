// SPDX-License-Identifier: GPL-3.0-or-later
// Upstream defaults allReadyAfter to '?' BEFORE async initialization finishes.
export function isUpstreamReady(ubo, errors = []) {
    return ubo.readyToFilter === true && errors.length === 0 &&
        /^\d+ ms(?: \(selfie\))?$/.test(ubo.supportStats?.allReadyAfter || '');
}
