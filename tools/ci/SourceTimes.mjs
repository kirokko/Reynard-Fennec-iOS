// Xcode sees unchanged checkout files as unchanged; changed bytes never inherit old times.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { sha } from './CachePayload.mjs';
const directory = process.env.REYNARD_DERIVED_DATA;
if (!directory) throw Error('REYNARD_DERIVED_DATA is required');
const manifest = path.join(directory, 'source-times.json');
const files = execFileSync('git', ['ls-files', '-z', 'browser', 'tools/release/build-app.sh'], { encoding: 'utf8' }).split('\0').filter(Boolean);
if (process.argv[2] === 'restore') {
  let old = {};
  try { old = JSON.parse(fs.readFileSync(manifest)); } catch { /* Cold cache. */ }
  let reused = 0;
  for (const file of files) {
    if (!fs.existsSync(file) || !fs.statSync(file).isFile()) continue;
    const stat = fs.statSync(file), digest = sha(fs.readFileSync(file));
    const same = old[file]?.sha === digest;
    const seconds = same ? old[file].seconds : Math.max(Math.floor(Date.now() / 1000), (old[file]?.seconds ?? 0) + 1);
    fs.utimesSync(file, stat.atime, seconds);
    if (same) reused++;
  }
  console.log(`Xcode timestamps restored for ${reused}/${files.length} content-identical tracked files`);
} else if (process.argv[2] === 'save') {
  const result = {};
  for (const file of files) if (fs.existsSync(file) && fs.statSync(file).isFile()) result[file] = { sha: sha(fs.readFileSync(file)), seconds: Math.floor(fs.statSync(file).mtimeMs / 1000) };
  fs.mkdirSync(directory, { recursive: true }); fs.writeFileSync(manifest, JSON.stringify(result));
} else throw Error('Expected restore or save');
