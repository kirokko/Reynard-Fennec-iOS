// SPDX-License-Identifier: GPL-3.0-or-later
// Integration tests against the actual hash-pinned full Firefox uBO modules.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { compileFilters } from '../../ports/ublock-webkit/convert.mjs';
globalThis.self = globalThis;
const source = path.resolve(process.argv[2]);
const output = path.resolve(process.argv[3]);
const api = {
    ...await import(pathToFileURL(path.join(source, 'js/static-dnr-filtering.js'))),
    ...await import(pathToFileURL(path.join(source, 'js/static-filtering-parser.js'))),
};
const cases = [];
async function check(name, test) { await test(); cases.push(name); }
await check('full package identity / license', () => {
    assert.equal(JSON.parse(fs.readFileSync(path.join(source, 'manifest.json'))).version, '1.76.4');
    assert.match(fs.readFileSync(path.join(source, 'LICENSE.txt'), 'utf8'), /GNU GENERAL PUBLIC LICENSE/);
});
await check('full compiler produces block and allow, not a hand-written ABP parser', async () => {
    const result = await compileFilters('/port/blocked.txt\n@@/port/allowed.txt', api);
    assert.equal(result.rules.length, 2);
    assert.deepEqual(new Set(result.rules.map(r => r.action.type)), new Set(['block', 'allow']));
    assert(result.rules.every(rule => Number.isInteger(rule.id) && Number.isInteger(rule.priority)));
});
await check('important block keeps upstream priority above ordinary exception', async () => {
    const { rules } = await compileFilters('/port/important.txt$important\n@@/port/important.txt', api);
    assert(rules.find(r=>r.action.type==='block').priority > rules.find(r=>r.action.type==='allow').priority);
    assert(!JSON.stringify(rules).includes('__important'));
});
await check('resource type condition retained', async () => {
    const { rules } = await compileFilters('/port/only-image$image', api);
    assert.deepEqual(rules[0].condition.resourceTypes, ['image']);
});
await check('domain / third-party conditions retained', async () => {
    const { rules } = await compileFilters('||example.test^$third-party,domain=site.test', api);
    assert.equal(rules[0].condition.domainType, 'thirdParty');
    assert.deepEqual(rules[0].condition.initiatorDomains, ['site.test']);
});
await check('incompatible redirect-rule is explicitly reported', async () => {
    const { report } = await compileFilters('||example.test^$redirect-rule=noopjs', api);
    assert(report.rejected.length > 0);
});
await check('HTML filtering never silently disappears', async () => {
    const { report } = await compileFilters('example.test##^script:has-text(advert)', api);
    assert(report.nonNetwork.some(r=>r.disposition==='unsupported-response-body-filtering'));
});
await check('cosmetic and scriptlets delegated, NOT claimed as installed', async () => {
    const { report } = await compileFilters('example.test##.ad\nexample.test##+js(set-constant, ad, true)', api);
    assert.equal(report.nonNetwork.length, 2);
    assert(report.nonNetwork.every(r=>r.disposition.includes('not-yet-verified')));
    assert.equal(report.nativeInstallationVerified, false);
});
await check('empty replacement compiles to empty rule set', async () => {
    assert.deepEqual((await compileFilters('', api)).rules, []);
});
const fixture = await compileFilters(fs.readFileSync(path.join(source, 'port/filters.txt'), 'utf8'), api);
fs.writeFileSync(path.join(output, 'fixture-compilation.json'), JSON.stringify(fixture, null, 2));
// Real bundled full-uBO list audit. NOT installed in the native smoke fixture.
const builtinPath = 'assets/ublock/filters.min.txt';
const builtin = await compileFilters(fs.readFileSync(path.join(source, builtinPath), 'utf8'), api, builtinPath);
fs.writeFileSync(path.join(output, 'bundled-list-audit.json'), JSON.stringify({
    installed: false, note: 'Conversion only, not a real-site filtering acceptance test', ...builtin.report,
}, null, 2));
fs.writeFileSync(path.join(output, 'compiler-tests.json'), JSON.stringify({ passed: cases, count: cases.length }, null, 2));
console.log(JSON.stringify({ passed: cases, bundledCandidateRules: builtin.rules.length,
    bundledRejected: builtin.report.rejected.length, bundledNonNetwork: builtin.report.nonNetwork.length }, null, 2));
