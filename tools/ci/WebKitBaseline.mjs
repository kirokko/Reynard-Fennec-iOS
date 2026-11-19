// GPL-3.0. Byte-level UI/data-schema baseline; NOT a screenshot/interaction test.
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const baselineFile = path.join(root, 'docs/webkit-migration/baseline.json');
// Windows checkouts may use CRLF. Ignore line-ending-only differences in text;
// binary resources remain byte-exact. Normalize both sides consistently.
const sha256 = bytes => createHash('sha256').update(bytes.includes(0) ? bytes : bytes.toString('utf8').replace(/\r\n/g, '\n')).digest('hex');
const git = args => execFileSync('git', args, {cwd: root, maxBuffer: 16 * 1024 * 1024});
const ref = '14452d327bf08c6222567adfd308701cf9e16e15';
if (process.argv.includes('--record')) {
    if (fs.existsSync(baselineFile)) throw new Error('Refusing to overwrite original baseline');
    const tracked = git(['ls-tree', '-r', ref]).toString().trim().split('\n').map(line => {
        const [metadata, file] = line.split('\t');
        return {file, object: metadata.split(' ')[2]};
    });
    const files = tracked.filter(({file}) => file.startsWith('browser/') || file.startsWith('.github/') || file.startsWith('tools/release/'));
    const manifest = files.map(({file, object}) => ({path: file, sha256: sha256(git(['cat-file', 'blob', object]))}));
    fs.mkdirSync(path.dirname(baselineFile), {recursive: true});
    fs.writeFileSync(baselineFile, JSON.stringify({commit: ref, scope: 'text normalized to LF; binary bytes exact; not runtime parity', files: manifest}, null, 2) + '\n');
    console.log(`Recorded ${manifest.length} files from ${ref}`);
} else {
    const baseline = JSON.parse(fs.readFileSync(baselineFile));
    const changed = baseline.files.filter(file => !fs.existsSync(path.join(root, file.path)) || sha256(fs.readFileSync(path.join(root, file.path))) !== file.sha256);
    console.log(JSON.stringify({baseline: baseline.commit, changed: changed.map(file => file.path)}, null, 2));
    // At this initial gate ONLY the opt-in CI entry point may change. Production
    // source/UI/data writers must remain intact until the integration is audited.
    if (changed.some(file => file.path !== '.github/workflows/build-sidestore.yml')) process.exitCode = 1;
}
