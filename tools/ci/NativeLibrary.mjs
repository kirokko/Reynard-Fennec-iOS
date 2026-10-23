import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { writeManifest, verifyManifest } from './CachePayload.mjs';
const stage = path.join(process.env.RUNNER_TEMP, 'ieynec-idevice');
const target = 'browser/Reynard/JIT/RPPairing/libidevice_ffi.a';
const entries = ['libidevice_ffi.a'];
const output = (k, v) => fs.appendFileSync(process.env.GITHUB_OUTPUT, `${k}=${v}\n`);
if (process.argv[2] === 'restore') {
  try {
    if (process.env.CACHE_HIT !== 'true') throw Error('No exact precompiled idevice hit');
    verifyManifest(stage, process.env.IDEVICE_KEY, entries);
    const source = path.join(stage, entries[0]);
    execFileSync('xcrun', ['lipo', source, '-verify_arch', 'arm64']);
    if (!execFileSync('ar', ['-t', source], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }).trim()) throw Error('Empty archive');
    execFileSync('cp', ['-p', source, target]); output('ready', 'true');
  } catch (error) { console.log(`::notice::idevice requires real build: ${error.message}`); output('ready', 'false'); }
} else if (process.argv[2] === 'pack') {
  fs.mkdirSync(stage, { recursive: true });
  execFileSync('cp', ['-p', target, path.join(stage, entries[0])]);
  execFileSync('xcrun', ['lipo', target, '-verify_arch', 'arm64']);
  writeManifest(stage, process.env.IDEVICE_KEY, entries);
} else throw Error('Expected restore or pack');
