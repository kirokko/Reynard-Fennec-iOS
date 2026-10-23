// Restore/export the complete app-facing SDK, including AddGecko.sh's source theme.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { writeManifest, verifyManifest } from './CachePayload.mjs';
const root = process.cwd();
const stage = path.join(process.env.RUNNER_TEMP, 'reynard-sdk-payload');
const archive = path.join(process.env.RUNNER_TEMP, 'reynard-gecko-dist.tar.gz');
const dist = 'engine/firefox/obj-aarch64-apple-ios/dist';
const theme = 'toolkit/mozapps/extensions/default-theme';
const entries = ['bin', 'include', 'default-theme'];
function output(k, v) { fs.appendFileSync(process.env.GITHUB_OUTPUT, `${k}=${v}\n`); }
function resetStage() { fs.rmSync(stage, { recursive: true, force: true }); fs.mkdirSync(stage, { recursive: true }); }
function required() {
  for (const file of ['bin/XUL', 'include/GeckoView/IOSBootstrap.h', 'include/GeckoView/GeckoViewSwiftSupport.h', 'default-theme/manifest.json']) {
    if (!fs.statSync(path.join(stage, file)).size) throw Error(`Empty SDK file: ${file}`);
  }
  if (!fs.readdirSync(path.join(stage, 'bin')).some(n => n.endsWith('.dylib'))) throw Error('Missing Gecko dylibs');
}
async function fetchTheme() {
  // Legacy v1 lacks the source theme. Migration is unsafe if current patches modify it.
  const patches = execFileSync('git', ['ls-files', 'patches'], { encoding: 'utf8' }).trim().split('\n');
  for (const patch of patches) if (/^(?:\+\+\+|---) [ab]\/toolkit\/mozapps\/extensions\/default-theme(?:\/|\s)/m.test(fs.readFileSync(patch, 'utf8'))) throw Error('Patched theme requires a source build');
  const commit = process.env.ENGINE_SHA;
  if (!/^[a-f0-9]{40}$/.test(commit)) throw Error('Expected pinned engine commit');
  async function directory(relative = '') {
    const url = `https://api.github.com/repos/mozilla-firefox/firefox/contents/${theme}${relative ? '/' + relative : ''}?ref=${commit}`;
    const res = await fetch(url, { headers: { Authorization: `Bearer ${process.env.GH_TOKEN}`, 'X-GitHub-Api-Version': '2022-11-28' } });
    if (!res.ok) throw Error(`Theme tree HTTP ${res.status}`);
    for (const item of await res.json()) {
      if (!/^[\w.\-]+$/.test(item.name) || item.name === '..') throw Error('Invalid theme path');
      const name = relative ? `${relative}/${item.name}` : item.name;
      if (item.type === 'dir') { await directory(name); continue; }
      if (item.type !== 'file') throw Error('Unsupported theme entry');
      const response = await fetch(item.download_url);
      if (!response.ok) throw Error(`Theme download HTTP ${response.status}`);
      const data = Buffer.from(await response.arrayBuffer());
      const blob = crypto.createHash('sha1').update(`blob ${data.length}\0`).update(data).digest('hex');
      if (blob !== item.sha) throw Error('Theme git blob checksum mismatch');
      const target = path.join(stage, 'default-theme', name);
      fs.mkdirSync(path.dirname(target), { recursive: true }); fs.writeFileSync(target, data);
    }
  }
  await directory();
}
if (process.argv[2] === 'restore') {
  try {
    const matched = process.env.MATCHED_KEY;
    if (!matched || ![process.env.SDK_KEY, process.env.LEGACY_SDK_KEY].includes(matched)) throw Error('No exact compatible SDK cache');
    resetStage(); execFileSync('tar', ['-xzf', archive, '-C', stage]);
    if (matched === process.env.SDK_KEY) verifyManifest(stage, process.env.SDK_KEY, entries);
    else { await fetchTheme(); required(); writeManifest(stage, process.env.SDK_KEY, entries); }
    required();
    fs.mkdirSync(dist, { recursive: true });
    for (const entry of ['bin', 'include']) { fs.rmSync(`${dist}/${entry}`, { recursive: true, force: true }); fs.renameSync(path.join(stage, entry), `${dist}/${entry}`); }
    const target = `engine/firefox/${theme}`;
    fs.mkdirSync(path.dirname(target), { recursive: true }); fs.rmSync(target, { recursive: true, force: true });
    fs.renameSync(path.join(stage, 'default-theme'), target);
    output('ready', 'true'); output('source', matched === process.env.SDK_KEY ? 'v2' : 'v1-migration');
  } catch (error) {
    console.log(`::notice::SDK unavailable/invalid; use real source build: ${error.message}`);
    // Only clean the synthetic SDK tree, never an initialized developer checkout.
    if (!fs.existsSync('engine/firefox/.git')) fs.rmSync('engine/firefox', { recursive: true, force: true });
    output('ready', 'false'); output('source', 'source-build');
  }
} else if (process.argv[2] === 'pack') {
  resetStage();
  for (const [src, name] of [[`${dist}/bin`, 'bin'], [`${dist}/include`, 'include'], [`engine/firefox/${theme}`, 'default-theme']]) {
    execFileSync('cp', ['-RL', path.join(root, src), path.join(stage, name)]);
  }
  required(); writeManifest(stage, process.env.SDK_KEY, entries);
  execFileSync('tar', ['-czf', archive, '-C', stage, ...entries, '.ci-payload.json']);
} else throw Error('Expected restore or pack');
