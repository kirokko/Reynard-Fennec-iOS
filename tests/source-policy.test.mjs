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

test('ieynec identity and supplied opaque app icon replace the first-build branding', () => {
  assert.match(read('browser/Configuration/Reynard.xcconfig'), /^APP_DISPLAY_NAME = ieynec$/m);
  assert.match(read(ui + 'Homepage/HomepageRootViewController.swift'), /brand.text = "ieynec"/);
  assert.doesNotMatch(read(ui + 'Library/Settings/SettingsViewController.swift'), /About Reynard Fennec/);
  const dir = 'browser/Reynard/Resources/Assets.xcassets/AppIcon.appiconset/';
  const catalog = JSON.parse(read(dir + 'Contents.json'));
  assert.equal(catalog.images.length, 1);
  assert.equal(catalog.images[0].filename, 'icon.png');
  const png = fs.readFileSync(path.join(root, dir, 'icon.png'));
  assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
  assert.equal(png.readUInt32BE(16), 1024);
  assert.equal(png.readUInt32BE(20), 1024);
  assert.equal(png[25], 2, 'app icon should be RGB without alpha');
  assert.ok(fs.existsSync(path.join(root, 'docs/artwork/ieynec.svg')));
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

test('second-pass homepage resumes real regular tabs and preserves extra sections', () => {
  const root = read(ui + 'Homepage/HomepageRootViewController.swift');
  assert.match(root, /UIStackView\(arrangedSubviews: \[logo, brand\]\)/);
  assert.match(root, /\$0 == \.frequentlyVisited/);
  assert.match(root, /FennecHomepageSummaryView/);
  const summary = read(ui + 'Homepage/FennecHomepageSummaryView.swift');
  assert.match(summary, /!\$0\.isPrivate/);
  assert.match(summary, /removeArrangedSubview\(continueStack\)/);
  assert.doesNotMatch(summary, /continueStack\.isHidden/);
  assert.match(summary, /onResume\?\(id\)/);
  assert.doesNotMatch(summary, /HistoryStore|RecentlyClosed/);
  const host = read(ui + 'BrowserViewController+ContentOverlay.swift');
  assert.match(host, /regularTabs\.firstIndex\(where: \{ \$0\.id == id \}\)/);
  assert.match(host, /blockedTrackers\(for: \$1\.session\)/);
});

test('homepage first-frame layout avoids collapsed required-height stacks and width feedback', () => {
  const root = read(ui + 'Homepage/HomepageRootViewController.swift');
  assert.doesNotMatch(root, /override func viewDidLayoutSubviews|widthAnchor\.constraint\(equalToConstant: 1\)|extras\.isHidden/);
  assert.match(root, /equalTo: scrollView\.frameLayoutGuide\.widthAnchor/);
  assert.match(root, /sectionStackView\.removeArrangedSubview\(extras\)/);
  assert.match(root, /if extras\.arrangedSubviews\.isEmpty/);
  const summary = read(ui + 'Homepage/FennecHomepageSummaryView.swift');
  assert.doesNotMatch(summary, /continueStack\.isHidden/);
  assert.match(summary, /if titleLabel\.text != title/);
  assert.match(read('.github/workflows/build.yml'), /bash tools\/Test-HomepageLayout\.sh/);
});

test('native tab groups reference live UUIDs, exclude private tabs, and have persistence tests', () => {
  const store = read('browser/Reynard/Client/TabManagement/TabGroupStore.swift');
  assert.match(store, /tabIDs: \[UUID\]/);
  assert.match(store, /JSONEncoder\(\)\.encode\(groups\)/);
  assert.doesNotMatch(store, /BookmarkStore|\.url|\.title|GeckoSession/);
  const page = read(ui + 'TabOverview/FennecTabGroupsViewController.swift');
  assert.match(page, /tabs\(\)\.filter \{ !\$0\.isPrivate && selected\.contains\(\$0\.id\) \}/);
  assert.match(page, /onSelect\(id\)/);
  assert.match(page, /store\.removeTab/);
  assert.doesNotMatch(page, /inactive|auto.close|Sync/i);
  assert.match(read('.github/workflows/build.yml'), /tests\/tab-groups\.test\.swift/);
});

test('motion-free policy covers UIKit, toolbar display link and tab overview state machine', () => {
  assert.match(read('browser/Reynard/AppDelegate.swift'), /UIView\.setAnimationsEnabled\(false\)/);
  assert.match(read(ui + 'Chrome/Toolbar/ToolbarController.swift'), /guard UIView\.areAnimationsEnabled else/);
  assert.match(read(ui + 'TabOverview/TabOverviewPresentation.swift'), /let animated = animated && UIView\.areAnimationsEnabled/);
  assert.match(read(ui + 'TabOverview/TabOverviewCollection.swift'), /guard UIView\.areAnimationsEnabled else/);
  const menu = read(ui + 'Chrome/FennecMenuViewController.swift');
  assert.doesNotMatch(menu, /animated: true/);
  const actions = read(ui + 'BrowserViewController+BrowserActions.swift');
  assert.match(actions, /modalPresentationStyle = \.fullScreen/);
  assert.doesNotMatch(actions, /let libraryController = LibraryViewController/);
});

test('menu routes connect to original engine actions instead of placeholder handlers', () => {
  const menu = read(ui + 'BrowserViewController+FennecMenu.swift');
  for (const operation of ['addressBarDidRequestReader', 'addressBarDidRequestPageZoom', 'addressBarDidRequestFindInPage', 'addressBarDidRequestWebsiteModeChange', 'addressBarDidRequestReloadOrStop', 'addressBarDidRequestHardReload', 'addressBarAddonItems', 'presentBookmarkEditor', 'presentLibrary']) assert.ok(menu.includes(operation), operation);
});
