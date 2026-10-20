import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const ui = 'browser/Reynard/Client/Interface/';
function files(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const p = path.join(directory, entry.name);
    return entry.isDirectory() ? files(p) : [p];
  });
}

test('all string catalogs are valid JSON with nonempty source language', () => {
  const catalogs = files(path.join(root, 'browser')).filter(p => p.endsWith('.xcstrings'));
  assert.ok(catalogs.length > 0);
  for (const file of catalogs) {
    const json = JSON.parse(fs.readFileSync(file, 'utf8'));
    assert.ok(json.sourceLanguage, file);
    assert.equal(typeof json.strings, 'object', file);
  }
});

test('new static UI strings have Simplified Chinese translations', () => {
  const catalog = JSON.parse(read(ui + 'Appearance/FennecLocalizable.xcstrings'));
  const swift = files(path.join(root, ui)).filter(p => p.endsWith('.swift'));
  const keys = new Set();
  for (const p of swift) {
    for (const match of fs.readFileSync(p, 'utf8').matchAll(/FennecTheme\.text\("([^"\n]+)"\)/g)) keys.add(match[1]);
  }
  for (const key of keys) assert.ok(catalog.strings[key]?.localizations?.['zh-Hans']?.stringUnit?.value, key);
});

test('manual application updates do not fetch any upstream feed', () => {
  const source = read('browser/Reynard/Client/Startup/BrowserUpdates.swift');
  assert.match(source, /let hasUpdate = false/);
  assert.match(source, /let sourceData: Data\? = nil/);
  assert.doesNotMatch(source, /URLSession|Data\(contentsOf:|fetchUpdates\(|https:\/\//);
});

test('only manually dispatched standard SideStore build is exposed', () => {
  const dir = path.join(root, '.github/workflows');
  const names = fs.readdirSync(dir).filter(p => p.endsWith('.yml'));
  assert.deepEqual(names.sort(), ['build-sidestore.yml', 'build.yml']);
  const workflow = read('.github/workflows/build-sidestore.yml');
  assert.match(workflow, /workflow_dispatch:/);
  assert.match(workflow, /build_normal_ipa: true/);
  assert.match(workflow, /build_trollstore_tipa: false/);
  assert.match(workflow, /build_jailbroken_ipa: false/);
  for (const p of names) assert.doesNotMatch(read('.github/workflows/' + p), /\bschedule:|\bpush:|\bpull_request:/);
});

test('settings keep the agreed groups and engine controls', () => {
  const settings = read(ui + 'Library/Settings/SettingsViewController.swift');
  assert.match(settings, /\["Search", "Tabs", "Homepage", "Customize", "Accessibility", "Language"\]/);
  assert.match(settings, /jitSection\.attach\(to: self\)/);
  assert.match(settings, /jitSection\.savePairingFile/);
  assert.doesNotMatch(settings, /DefaultBrowser|MakeDefault|Set as default/);
  const advanced = read(ui + 'Library/Settings/Sections/Advanced/AdvancedSettingsSection.swift');
  for (const name of ['DeveloperPreferencesViewController', 'CompatibilityPreferencesViewController', 'BrowsingPreferencesViewController']) assert.ok(advanced.includes(name));
});

test('menu routes connect to original engine actions instead of placeholder handlers', () => {
  const menu = read(ui + 'BrowserViewController+FennecMenu.swift');
  for (const operation of ['addressBarDidRequestReader', 'addressBarDidRequestPageZoom', 'addressBarDidRequestFindInPage', 'addressBarDidRequestWebsiteModeChange', 'addressBarDidRequestReloadOrStop', 'addressBarDidRequestHardReload', 'addressBarAddonItems', 'presentBookmarkEditor', 'presentLibrary']) assert.ok(menu.includes(operation), operation);
});
