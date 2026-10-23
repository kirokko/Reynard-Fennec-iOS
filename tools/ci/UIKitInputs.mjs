// Hash the inputs actually compiled by the existing UIKit host. Mandatory Node,
// Foundation and whole-browser Swift parsing still execute on EVERY IPA run.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';
export function fixtureInputs(root) {
  const tracked = execFileSync('git', ['ls-files', '-z'], { cwd: root, encoding: 'utf8' }).split('\0').filter(Boolean);
  const script = fs.readFileSync(path.join(root, 'tools/Test-HomepageLayout.sh'), 'utf8');
  const ui = script.match(/^ui=(\S+)$/m)?.[1];
  const tokens = [...script.matchAll(/[^\s"'\\]+\.swift/g)].map(m => m[0].replace(/\$ui\//g, ui + '/'));
  const resolvable = ui && tokens.length > 10 && tokens.every(f => /^(browser|tests)\//.test(f) && fs.existsSync(path.join(root, f)) && !/[\$*?]/.test(f));
  if (!resolvable) console.error('UIKit input declaration changed; conservatively hash all browser/tests inputs.');
  return [...new Set([
    ...tokens.filter(f => tracked.includes(f)),
    ...tracked.filter(f => resolvable
      ? f.startsWith('tests/ui-layout-smoke/') || f.startsWith('browser/Reynard/Resources/Assets.xcassets/')
      : f.startsWith('browser/') || f.startsWith('tests/')),
    'tools/Test-HomepageLayout.sh', 'tools/ci/UIKitInputs.mjs', '.github/actions/browser-checks/action.yml',
  ])].sort();
}
export function fixtureDigest(root) {
  const hash = createHash('sha256');
  for (const file of fixtureInputs(root)) hash.update(file).update('\0').update(fs.readFileSync(path.join(root, file))).update('\0');
  return hash.digest('hex');
}
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) console.log(fixtureDigest(process.cwd()));
