import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { writeManifest, verifyManifest } from '../tools/ci/CachePayload.mjs';
import { fixtureInputs } from '../tools/ci/UIKitInputs.mjs';
const root = fileURLToPath(new URL('../', import.meta.url));
const read = f => fs.readFileSync(path.join(root, f), 'utf8');

test('native payload accepts exact inputs and fails closed on corruption, missing files or identity changes', t => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ieynec-payload-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  fs.mkdirSync(path.join(dir, 'bin')); fs.writeFileSync(path.join(dir, 'bin/XUL'), 'synthetic inventory fixture, not an SDK');
  writeManifest(dir, 'key-1', ['bin']);
  assert.equal(verifyManifest(dir, 'key-1', ['bin']), true);
  assert.throws(() => verifyManifest(dir, 'key-2', ['bin']), /identity/);
  fs.writeFileSync(path.join(dir, 'bin/XUL'), 'corrupted');
  assert.throws(() => verifyManifest(dir, 'key-1', ['bin']), /contents/);
  fs.unlinkSync(path.join(dir, 'bin/XUL'));
  assert.throws(() => verifyManifest(dir, 'key-1', ['bin']), /contents|Empty/);
});

test('source timestamp reuse is content-addressed, changed source cannot inherit cached time', t => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ieynec-times-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  fs.mkdirSync(path.join(dir, 'browser'));
  fs.writeFileSync(path.join(dir, 'browser/a.swift'), 'original');
  execFileSync('git', ['init', '-q', dir]); execFileSync('git', ['-C', dir, 'add', '.']);
  const env = { ...process.env, REYNARD_DERIVED_DATA: path.join(dir, 'derived') };
  const run = mode => execFileSync(process.execPath, [path.join(root, 'tools/ci/SourceTimes.mjs'), mode], { cwd: dir, env });
  run('restore'); run('save');
  const original = fs.statSync(path.join(dir, 'browser/a.swift')).mtimeMs;
  fs.utimesSync(path.join(dir, 'browser/a.swift'), 1, 1); run('restore');
  assert.equal(fs.statSync(path.join(dir, 'browser/a.swift')).mtimeMs, original);
  fs.writeFileSync(path.join(dir, 'browser/a.swift'), 'modified'); run('restore');
  assert.ok(fs.statSync(path.join(dir, 'browser/a.swift')).mtimeMs > original);
});

test('cached SDK includes the otherwise source-dependent default theme before skipping checkout', () => {
  const workflow = read('.github/workflows/build.yml');
  assert.ok(workflow.indexOf('Restore packaged Gecko SDK before source preparation') < workflow.indexOf('Initialize required submodules'));
  for (const name of ['Update Gecko source', 'Apply Gecko patches', 'Build Gecko on SDK miss']) {
    assert.ok(workflow.slice(workflow.indexOf('- name: ' + name), workflow.indexOf('- name: ' + name) + 200).includes("if: steps.sdk.outputs.ready != 'true'"));
  }
  const sdk = read('tools/ci/NativeSDK.mjs');
  assert.match(sdk, /default-theme\/manifest\.json/);
  assert.match(sdk, /verifyManifest/);
  assert.match(sdk, /item\.sha/);
  assert.match(sdk, /Patched theme requires a source build/);
  assert.match(workflow, /git rev-parse HEAD:support\/idevice/);
  assert.match(workflow, /if: steps.idevice.outputs.ready != 'true'/);
});

test('cache optimization preserves build types, required validation, fresh packaging and accurate provenance', () => {
  const workflow = read('.github/workflows/build.yml');
  for (const input of ['checkout_ref', 'nightly', 'build_normal_ipa', 'build_trollstore_tipa', 'build_jailbroken_ipa']) assert.ok(workflow.includes(input + ':'));
  for (const artifact of ['Reynard-Fennec-SideStore', 'Reynard-TrollStore.tipa', 'Reynard-Jailbroken.ipa']) assert.ok(workflow.includes(artifact));
  assert.match(workflow, /Verify-IPA\.py/);
  const app = read('tools/release/build-app.sh');
  assert.match(app, /rm -rf "\$DIST_DIR"/);
  for (const setting of ['SWIFT_ENABLE_COMPILE_CACHE=YES', 'CLANG_ENABLE_COMPILE_CACHE=YES', 'COMPILATION_CACHE_CAS_PATH=']) assert.ok(app.includes(setting));
  const checks = read('.github/actions/browser-checks/action.yml');
  for (const required of ['node --test tests/*.test.mjs', 'bash tools/ci/Test-Foundation.sh', 'xcrun swiftc -frontend -parse']) assert.ok(checks.includes(required));
  assert.match(checks, /node tools\/ci\/UIKitInputs\.mjs/);
  const inputs = fixtureInputs(root);
  for (const required of ['tests/ui-layout-smoke/App.swift', 'browser/Reynard/Client/Interface/Chrome/FennecSearchPopup.swift', 'browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBarTextField.swift', 'tools/Test-HomepageLayout.sh']) assert.ok(inputs.includes(required), required);
  assert.ok(!inputs.includes('browser/Reynard/Client/Interface/BrowserViewController.swift'), 'Uncompiled browser routes must not force an identical UIKit host rerun');
  assert.doesNotMatch(checks, /restore-keys:/);
  const wrapper = read('.github/workflows/build-sidestore.yml');
  assert.match(wrapper, /ui_checks_only:/);
  assert.match(wrapper, /strategy: full/);
  assert.match(wrapper, /default: auto/);
  const fixture = read('tools/Test-HomepageLayout.sh');
  assert.ok(fixture.indexOf('xcrun simctl boot "$device"') < fixture.indexOf('xcrun swiftc -g'));
  assert.ok(fixture.indexOf('xcrun simctl bootstatus') > fixture.indexOf('xcrun swiftc -g'));
});
