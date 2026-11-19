// SPDX-License-Identifier: GPL-3.0-or-later
// Platform boundary around the converter shipped INSIDE full Firefox uBO.
// No replacement parser, Lite package, or fake webRequest implementation.
export const environment = ['ublock', 'webext', 'ipaddress', 'mobile', 'safari', 'native_css_has'];

export async function compileFilters(text, { dnrRulesetFromRawLists, AstFilterParser }, name = 'user-filters') {
    if (typeof text !== 'string') throw new TypeError('Filter source must be text');
    const result = await dnrRulesetFromRawLists([{ name, text, trustedSource: false }], { env: environment });
    const rules = [];
    const rejected = [];
    for (const rule of result.network.ruleset) {
        if (rule._error !== undefined) { rejected.push(rule._error); continue; }
        // uBO's __important etc are compiler annotations, not DNR properties.
        // Keep its actual priority/action/condition, NOT a home-made mapping.
        rules.push({ id: rule.id, priority: rule.priority, action: rule.action, condition: rule.condition });
    }
    const parser = new AstFilterParser({ toDNR: true, nativeCssHas: true, trustedSource: false });
    const nonNetwork = [];
    const directives = [];
    for (const [index, line] of text.split(/\r?\n/).entries()) {
        if (/^!#/.test(line)) directives.push({ line: index + 1, text: line, note: 'Handled by upstream preparser; environment recorded in report' });
        parser.parse(line);
        if (!parser.isFilter() || !parser.isExtendedFilter()) continue;
        let disposition = 'delegated-to-original-content-engine-not-yet-verified';
        if (parser.isScriptletFilter()) disposition = 'scriptlet-delegated-to-original-engine-not-yet-verified';
        if (parser.isHtmlFilter()) disposition = 'unsupported-response-body-filtering';
        if (parser.isResponseheaderFilter()) disposition = 'response-header-rule-submitted-to-DNR-unverified';
        nonNetwork.push({ line: index + 1, text: line, disposition, parseError: parser.hasError() });
    }
    return {
        rules,
        report: {
            source: name, environment, sourceLines: text.split(/\r?\n/).length,
            network: { ...result.network, ruleset: undefined },
            candidateRuleCount: rules.length, rejected, nonNetwork, directives,
            ruleToSourceMapping: 'Upstream merges/splits network rules; no claim of one output rule per input line',
            nativeInstallationVerified: false,
            unsupported: ['blocking webRequest return channel', 'response body filtering', 'CNAME uncloaking',
                'dynamic firewall/URL rules bridge', 'site power switch/whitelist bridge', 'network log accuracy',
                'full filter-list selection/update bridge'],
        },
    };
}
