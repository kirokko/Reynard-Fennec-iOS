import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { createHash } from 'node:crypto';
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

test('new static UI strings have Simplified and Traditional Chinese translations', () => {
  const catalog = JSON.parse(read(ui + 'Appearance/FennecLocalizable.xcstrings'));
  const swift = files(path.join(root, ui)).filter(p => p.endsWith('.swift'));
  const keys = new Set();
  for (const p of swift) {
    for (const match of fs.readFileSync(p, 'utf8').matchAll(/FennecTheme\.text\("([^"\n]+)"\)/g)) keys.add(match[1]);
  }
  for (const key of keys) {
    for (const language of ['zh-Hans', 'zh-Hant']) assert.ok(catalog.strings[key]?.localizations?.[language]?.stringUnit?.value, `${language}: ${key}`);
  }
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
  assert.doesNotMatch(settings, /jitSection|case \.jit|JITSettingsSection/);
  assert.doesNotMatch(settings, /DefaultBrowser|MakeDefault|Set as default/);
  const advanced = read(ui + 'Library/Settings/Sections/Advanced/AdvancedSettingsSection.swift');
  for (const name of ['DeveloperPreferencesViewController', 'CompatibilityPreferencesViewController', 'BrowsingPreferencesViewController']) assert.ok(advanced.includes(name));
});

test('second-pass homepage resumes real regular tabs and preserves extra sections', () => {
  const root = read(ui + 'Homepage/HomepageRootViewController.swift');
  assert.match(root, /UIStackView\(arrangedSubviews: \[logo, brand\]\)/);
  assert.doesNotMatch(root, /\$0 == \.frequentlyVisited/);
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

test('motion-free policy keeps only the requested user-scroll chrome exception', () => {
  assert.match(read('browser/Reynard/AppDelegate.swift'), /UIView\.setAnimationsEnabled\(false\)/);
  const toolbar = read(ui + 'Chrome/Toolbar/ToolbarController.swift');
  assert.match(toolbar, /guard FennecTheme\.animatesBrowserUI \|\| permitsScrollMotion else/);
  assert.match(toolbar, /permitsScrollMotion = chromeMode == \.phone/);
  assert.match(toolbar, /private func cancelAnimation\(\) \{\s*permitsScrollMotion = false/);
  const presentation = read(ui + 'TabOverview/TabOverviewPresentation.swift');
  assert.doesNotMatch(presentation, /UIView\.animate|usingSpring|scaleX:|presentOnPhone|presentOnPad/);
  assert.match(presentation, /UIView\.performWithoutAnimation/);
  assert.match(presentation, /presentationToken == token/);
  assert.match(read(ui + 'TabOverview/TabOverviewCollection.swift'), /guard FennecTheme\.animatesBrowserUI else/);
  assert.match(read(ui + 'Appearance/FennecTheme.swift'), /static let animatesBrowserUI = false/);
  assert.match(read('tests/ui-layout-smoke/TrayFixtures.swift'), /UIView\.setAnimationsEnabled\(true\)/);
  const menu = read(ui + 'Chrome/FennecMenuViewController.swift');
  assert.doesNotMatch(menu, /animated: true/);
  const actions = read(ui + 'BrowserViewController+BrowserActions.swift');
  assert.match(actions, /modalPresentationStyle = \.fullScreen/);
  assert.doesNotMatch(actions, /let libraryController = LibraryViewController/);
});

test('JIT removal keeps only the required Gecko no-JIT status handshake', () => {
  const controller = read('browser/Reynard/JIT/JITController.swift');
  assert.match(controller, /ReportJITStatusForChild\(pid, false, runtime\)/);
  assert.match(controller, /Prefs\.JITSettings\.isJITEnabled = false/);
  assert.doesNotMatch(controller, /JITEnabler|DDIManager|BackgroundAudioManager|presentEnablementFailureScreen|tunnel_create|schedulePreflight/);
  assert.doesNotMatch(read('browser/Reynard/AppDelegate.swift'), /startBackgroundAudio/);
  const prefs = read('browser/Reynard/Client/Preferences/BrowserPreferences.swift').split('struct JITSettings')[1].split('// MARK: - Bookmarks')[0];
  assert.doesNotMatch(prefs, /return prefs\.bool|hasPairingFile && newValue/);
});

test('address focus and keyboard docking commit app-owned chrome without animation', () => {
  const browser = read(ui + 'BrowserViewController.swift');
  assert.doesNotMatch(browser, /animateLayout\(animation\)|private func animateLayout|animationDuration: animation\.duration/);
  assert.match(browser, /UIView\.performWithoutAnimation \{\s*browserChrome\.dockActionBar/);
  const search = read(ui + 'Search/SearchOverlayCoordinator.swift');
  assert.match(search, /dismiss\(\.search, animated: animated && FennecTheme\.animatesBrowserUI\)/);
  assert.match(search, /on: targetHost,\s*animated: animated && FennecTheme\.animatesBrowserUI/);
  const gestures = read(ui + 'Chrome/AddressBar/AddressBarGestures.swift');
  const newTab = gestures.split('func animateAutomaticNewTabTransition')[1].split('private func setupSourceContentPreview')[0];
  assert.doesNotMatch(newTab, /UIView\.animate|translationX|snapshotView/);
});

test('private pages and tray follow the filmed Android structure without fake counters', () => {
  const home = read(ui + 'Homepage/HomepageRootViewController.swift');
  assert.match(home, /folder == nil && !isPrivateBrowsing \{\s*let header/);
  assert.match(home, /case \.recommendation\(\.donation\):\s*return !isPrivateBrowsing/);
  const page = read(ui + 'Homepage/Sections/PrivateBrowsing/PrivateBrowsingSectionViewController.swift');
  assert.match(page, /Leave no traces on this device/);
  assert.doesNotMatch(page, /UIVisualEffectView|UIBlurEffect/);
  const tray = read(ui + 'TabOverview/TabOverview.swift');
  assert.match(tray, /privateEmptyState\.isHidden = !isPrivate \|\| visibleCount > 0/);
  const menu = read(ui + 'BrowserViewController+TabPresentation.swift');
  for (const label of ['Recently closed tabs', 'Tab settings', 'Close all tabs']) assert.ok(menu.includes(label));
  assert.doesNotMatch(read(ui + 'TabOverview/TabOverviewToolbar/TabOverviewTopToolbar.swift'), /showsMenuAsPrimaryAction/);
});

test('homepage switches control real cards and omit the obsolete update switch', () => {
  const page = read(ui + 'Library/Settings/Sections/General/Homepage/HomepagePreferencesViewController.swift');
  assert.doesNotMatch(page, /newUpdatesSwitch|case newUpdates/);
  assert.match(page, /Prefs\.HomepageSettings\.showsContinue = sender\.isOn/);
  assert.match(page, /Prefs\.HomepageSettings\.showsProtection = sender\.isOn/);
  const summary = read(ui + 'Homepage/FennecHomepageSummaryView.swift');
  assert.match(summary, /removeArrangedSubview\(protectionRow\)/);
  assert.match(summary, /Prefs\.HomepageSettings\.showsContinue else/);
  const source = read(ui + 'BrowserViewController+TabPresentation.swift');
  const select = source.split('func selectTab(at index:')[1].split('func closeTab')[0];
  assert.doesNotMatch(select, /\[weak self\]|self\?\.tabManager\.selectTab/);
});

test('filmed download categories and bookmark sort choices use original stores', () => {
  const downloads = read(ui + 'Library/Downloads/DownloadsViewController.swift');
  assert.match(downloads, /filterView\.selected\.matches\(fileName: \$0\.fileName, mimeType: \$0\.mimeType\)/);
  assert.match(downloads, /DownloadStore\.shared\.currentSnapshot\(\)/);
  const bookmarks = read(ui + 'Library/Bookmarks/BookmarksViewController.swift');
  for (const key of ['Sort by custom order', 'Sort by newest', 'Sort by oldest', 'Sort by A to Z', 'Sort by Z to A']) assert.ok(bookmarks.includes(key));
  assert.match(bookmarks, /folder\.isProtected \{\s*return item/);
  const catalog = JSON.parse(read(ui + 'Appearance/FennecLocalizable.xcstrings'));
  for (const key of ['All', 'Images', 'Other']) for (const language of ['zh-Hans', 'zh-Hant']) assert.ok(catalog.strings[key].localizations[language]);
});

test('new reference chrome has real plus buttons, a single privacy mask and no fake sync entry', () => {
  const theme = read(ui + 'Appearance/FennecTheme.swift');
  assert.match(theme, /for button in \[newTabButton, tabButton, menuButton\]/);
  assert.match(theme, /widthAnchor\.constraint\(equalToConstant: 132\)/);
  assert.doesNotMatch(theme, /UIImage\(named: "private.mode.icon"\)|systemName: "theatermasks"/);
  assert.match(theme, /UIImage\(named: "FennecPrivateMask"\)/);
  const mask = read('browser/Reynard/Resources/Assets.xcassets/FennecPrivateMask.imageset/mask.svg');
  assert.match(mask, /Mozilla Public/);
  assert.match(mask, /FIREFOX-ANDROID_158_0_RELEASE/);
  const paths = [...mask.matchAll(/ d="([^"]+)"/g)].map(m => m[1]);
  assert.equal(paths.length, 3);
  assert.equal(createHash('sha256').update(paths.join('\n')).digest('hex'), 'b350e2ab15e0a923b5e0496e0df89614a02381d477cfa55d7f9bd6cf6b4c5a77');
  assert.match(read('tools/Test-HomepageLayout.sh'), /xcrun actool/);
  for (const name of ['TopToolbar', 'BottomToolbar']) {
    const toolbar = read(ui + `Chrome/Toolbar/${name}.swift`);
    assert.match(toolbar, /editing \? -8 : -140/);
    assert.match(toolbar, /controls.onNewTab = \{ \[weak self\] in self\?\.onNewTab\?\(\) \}/);
  }
  const tray = read(ui + 'TabOverview/TabOverviewToolbar/TabOverviewTopToolbar.swift');
  assert.doesNotMatch(tray, /syncButton|onSync|Sync tabs/);
});

test('fullscreen starts portrait and uses a scoped gravity sensor instead of changing system lock', () => {
  const source = read(ui + 'FennecFullscreenRotation.swift');
  assert.match(source, /mutating func enter\(\) \{\s*mode = \.portrait\s*orientation = \.portrait/);
  assert.match(source, /guard mode == \.landscape, orientation != side/);
  assert.match(source, /candidateSamples >= 2/);
  assert.match(source, /startAccelerometerUpdates\(to: \.main\)/);
  assert.match(source, /willResignActiveNotification/);
  assert.match(source, /motion.stopAccelerometerUpdates\(\)/);
  assert.doesNotMatch(source, /setValue\(|orientationLock|UIAppRotation/);
  const browser = read(ui + 'BrowserViewController.swift');
  assert.match(browser, /return fullscreenRotation.state.mask/);
  assert.match(browser, /fullscreenRotation\.enter\(\)/);
  assert.match(browser, /fullscreenRotation\.exit\(\)/);
  assert.match(browser, /currentMask.map \{ requestedOrientations.contains\(\$0\) \}/);
  assert.match(browser, /requestGeometryUpdate\(geometryPreferences\) \{/);
  const catalog = JSON.parse(read(ui + 'Appearance/FennecLocalizable.xcstrings'));
  for (const key of ['Rotate video', 'Return to portrait', 'Landscape follows device', 'Portrait', 'Unable to rotate video']) {
    for (const lang of ['zh-Hans', 'zh-Hant']) assert.ok(catalog.strings[key]?.localizations[lang]?.stringUnit.value);
  }
});

test('pull to refresh overlays a disc without displacing the page or issuing a fake reload', () => {
  const web = read(ui + 'ContentView/WebContentView.swift');
  assert.doesNotMatch(web, /webView.transform|usingSpringWithDamping|UIActivityIndicatorView/);
  assert.match(web, /session.reload\(\)/);
  assert.match(web, /static let refreshThreshold: CGFloat = 96/);
  assert.match(web, /refreshIndicatorContainer.transform/);
  const indicator = read(ui + 'ContentView/FennecRefreshIndicator.swift');
  assert.match(indicator, /CGSize\(width: 40, height: 40\)/);
  assert.match(indicator, /removeAnimation\(forKey: "refresh.spin"\)/);
  const fixture = read('tests/ui-layout-smoke/ChromeFixtures.swift');
  assert.match(fixture, /checkFullscreenRotationAndRefresh/);
  assert.match(fixture, /Stale full-screen controls/);
});

test('removed frequent sites cannot return through old preferences or settings; shortcuts migrate once', () => {
  const sections = read(ui + 'Homepage/Sections/HomepageSection.swift').split('static var allCases')[1];
  assert.doesNotMatch(sections, /\.frequentlyVisited/);
  const root = read(ui + 'Homepage/HomepageRootViewController.swift');
  assert.match(root, /case \.frequentlyVisited:\s*\/\/[^]*?return false/);
  const rows = read(ui + 'Library/Settings/Sections/General/Homepage/HomepageSection/HomepageSectionPreferencesViewController.swift').split('enum Preference')[0];
  assert.doesNotMatch(rows, /frequentlyVisited/);
  const prefs = read('browser/Reynard/Client/Preferences/BrowserPreferences.swift');
  assert.match(prefs, /if !UserDefaults.standard.bool\(forKey: shortcutDefaultKey\)/);
  assert.match(prefs, /set\(true, forKey: key\("HomepageSettings", "showsFavorites"\)\)/);
});

test('phone scroll translates the complete row without miniature URL, fade or delayed follow', () => {
  const chrome = read(ui + 'Chrome/BrowserChrome.swift');
  assert.match(chrome, /if mode == \.phone \{ return 0 \}/);
  assert.match(chrome, /state.mode != \.phone/);
  assert.match(chrome, /bottomToolbar.setScrollTranslation\(bottomOffset\)/);
  const bottom = read(ui + 'Chrome/Toolbar/BottomToolbar.swift');
  assert.doesNotMatch(bottom, /rowViewport|backgroundView.alpha/);
  assert.match(bottom, /transform = CGAffineTransform\(translationX: 0, y: offset\)/);
  const controller = read(ui + 'Chrome/Toolbar/ToolbarController.swift');
  assert.match(controller, /transitionOffset \+ delta, 0/);
  assert.match(controller, /if !isScrollTouchActive \{ scheduleSnap\(\) \}/);
  assert.match(controller, /chromeMode == \.phone \? 0.15 : UX.snapDuration/);
  for (const name of ['ContentView', 'WebContentView']) {
    const source = read(ui + 'ContentView/' + name + '.swift');
    assert.match(source, /onScrollInteractionBegan/);
    assert.match(source, /onScrollInteractionEnded/);
  }
  assert.match(read('tools/Test-HomepageLayout.sh'), /ToolbarController.swift/);
  assert.match(read('tests/ui-layout-smoke/ScrollFixtures.swift'), /expect\(visible \+ 4\)/);
});

test('collapsed phone viewport releases the system inset and shortcuts size on their first parent layout', () => {
  const toolbar = read(ui + 'Chrome/Toolbar/ToolbarController.swift');
  assert.match(toolbar, /minHeight: canHideToolbar && chromeMode != \.phone/);
  assert.match(toolbar, /contentBottomInset: 0/);
  assert.doesNotMatch(toolbar, /bottomSafeAreaHeight/);
  assert.match(toolbar, /bottom: bottomToolbarOffset,/);
  const bottom = read(ui + 'Chrome/Toolbar/BottomToolbar.swift');
  assert.doesNotMatch(bottom, /backgroundView.alpha/);
  const favorites = read(ui + 'Homepage/Sections/Favorites/FavoritesSectionViewController.swift');
  assert.match(favorites, /let width = view.bounds.width/);
  assert.doesNotMatch(favorites, /let width = collectionView.bounds.width/);
  const fixture = read('tests/ui-layout-smoke/FavoritesFixtures.swift');
  assert.match(fixture, /grid.bounds = \.zero/);
  assert.match(fixture, /grid.visibleCells.count == 6/);
  const script = read('tools/Test-HomepageLayout.sh');
  assert.match(script, /Sections\/Favorites\/FavoritesSectionViewController.swift/);
  assert.match(script, /Sections\/Favorites\/FavoritesCollectionViewLayout.swift/);
});

test('tray count refreshes its dynamic outline on first attachment and private empty state has one owner', () => {
  const theme = read(ui + 'Appearance/FennecTheme.swift');
  assert.match(theme, /class FennecTabCountLabel: UILabel/);
  assert.match(theme, /override func didMoveToWindow/);
  assert.match(theme, /override func layoutSubviews/);
  assert.match(read(ui + 'TabOverview/TabOverviewToolbar/TabOverviewTopToolbar.swift'), /countLabel = FennecTabCountLabel\(\)/);
  const collection = read(ui + 'TabOverview/TabOverviewCollection.swift');
  assert.doesNotMatch(collection, /privateModeIntroView|makePrivateModeIntroView|private.mode.icon|Reynard won/);
  assert.match(collection, /view.backgroundView = nil/);
  assert.match(read(ui + 'TabOverview/TabOverview.swift'), /tray.privateEmpty/);
  assert.match(read('tests/ui-layout-smoke/CountColorFixtures.swift'), /Second tap must not change/);
});

test('address appearance uses the pinned Android shield and URL without a page-title suffix', () => {
  const svg = read('browser/Reynard/Resources/Assets.xcassets/FennecProtectionShield.imageset/shield.svg');
  assert.match(svg, /Mozilla Public/);
  assert.match(svg, /FIREFOX-ANDROID_158_0_RELEASE/);
  const paths = [...svg.matchAll(/ d="([^"]+)"/g)].map(m => m[1]);
  assert.equal(paths.length, 2);
  assert.equal(createHash('sha256').update(paths.join('\n')).digest('hex'), '8a49d246b430e6382c5dfaf1b32574a7d14dcbfc16de75f9b18e02f4435e64d9');
  const address = read(ui + 'Chrome/AddressBar/AddressBar.swift');
  const display = address.split('private func displayAttributedText()')[1].split('private func locationHost()')[0];
  assert.match(display, /FennecAddressDisplay.text/);
  assert.doesNotMatch(display, /currentLocationTitle|NSMutableAttributedString/);
  assert.match(address, /addressBarButtonSize: CGFloat = 24/);
  assert.match(address, /addressBarTextFontSize: CGFloat = 16/);
  assert.doesNotMatch(address, /UIImage\(systemName: "checkmark.shield"\)/);
});

test('app icon uses a reproducible dimensional light surface instead of a white plate', () => {
  const script = read('tools/Prepare-AppIcon.sh');
  assert.match(script, /geq=r=/);
  assert.match(script, /gblur=sigma=/);
  assert.match(script, /format=rgb24/);
  assert.doesNotMatch(script, /rounded|roundrect/);
});

test('menu routes connect to original engine actions instead of placeholder handlers', () => {
  const menu = read(ui + 'BrowserViewController+FennecMenu.swift');
  for (const operation of ['addressBarDidRequestReader', 'addressBarDidRequestPageZoom', 'addressBarDidRequestFindInPage', 'addressBarDidRequestWebsiteModeChange', 'addressBarDidRequestReloadOrStop', 'addressBarDidRequestHardReload', 'addressBarAddonItems', 'presentBookmarkEditor', 'presentLibrary']) assert.ok(menu.includes(operation), operation);
});
