// Build cache integrity, never a substitute for compilation or IPA verification.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
export const sha = data => crypto.createHash('sha256').update(data).digest('hex');
export function inventory(root, entries) {
  const result = {};
  function visit(relative) {
    const file = path.join(root, relative);
    const stat = fs.lstatSync(file);
    if (stat.isSymbolicLink()) throw Error(`Non-self-contained cache: ${relative}`);
    if (stat.isDirectory()) for (const name of fs.readdirSync(file).sort()) visit(`${relative}/${name}`);
    else if (stat.isFile()) result[relative] = sha(fs.readFileSync(file));
  }
  for (const entry of entries) visit(entry);
  if (!Object.keys(result).length) throw Error('Empty payload');
  return result;
}
export function writeManifest(root, identity, entries) {
  const manifest = { version: 1, identity, entries, files: inventory(root, entries) };
  fs.writeFileSync(path.join(root, '.ci-payload.json'), JSON.stringify(manifest));
}
export function verifyManifest(root, identity, entries) {
  const m = JSON.parse(fs.readFileSync(path.join(root, '.ci-payload.json')));
  if (m.version !== 1 || m.identity !== identity || JSON.stringify(m.entries) !== JSON.stringify(entries)) throw Error('Cache identity mismatch');
  const actual = inventory(root, entries);
  if (JSON.stringify(actual) !== JSON.stringify(m.files)) throw Error('Cache contents mismatch');
  return true;
}
