import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const root = new URL('../', import.meta.url);
const read = p => fs.readFileSync(new URL(p, root), 'utf8');
const ui = 'browser/Reynard/Client/Interface/';

test('the requested four engines share one ordered list and real distinct endpoints', () => {
  const engines = read('browser/Reynard/Client/Search/SearchEngines.swift');
  assert.match(engines, /pickerEngines: \[SearchEngine\] = \[\.duckDuckGo, \.bingChina, \.duckDuckGoLite, \.duckDuckGoHTML\]/);
  for (const endpoint of ['https://cn.bing.com/search?q=%s', 'https://lite.duckduckgo.com/lite/?q=%s', 'https://html.duckduckgo.com/html/?q=%s']) assert.ok(engines.includes(endpoint));
  const settings = read(ui + 'Library/Settings/Sections/General/Search/SearchEngine/SearchEnginePreferencesViewController.swift');
  assert.match(settings, /SearchEngine\.pickerEngines/);
  assert.doesNotMatch(settings, /SearchEngine\.allCases/);
});

test('provider popup is narrow, anchored, separated into groups and not a bottom sheet', () => {
  const popup = read(ui + 'Chrome/FennecSearchPopup.swift');
  assert.match(popup, /sourceView.*UIView/);
  assert.match(popup, /bounds\.width \* 0\.58/);
  assert.match(popup, /sourceView\.map/);
  assert.match(popup, /divider\.backgroundColor = \.separator/);
  assert.match(popup, /dismiss\(animated: false, completion: item\.action\)/);
  assert.doesNotMatch(popup, /sheetPresentationController|pageSheet|crossDissolve|handle\.onTap/);
});

test('toolbar uses original curved Android tab vector and a private mask badge', () => {
  const theme = read(ui + 'Appearance/FennecTheme.swift');
  assert.match(theme, /usesAndroidOutline = true/);
  assert.match(theme, /UIImage\(named: "FennecTabOutline"\)/);
  assert.match(theme, /UIImageView\(image: UIImage\(named: "FennecPrivateTabBadge"\)\)/);
  assert.match(read(ui + 'BrowserViewController.swift'), /setPrivateBrowsing\(tabManager\.selectedTabMode == \.private\)/);
  for (const asset of ['FennecTabOutline', 'FennecBookmarkTray', 'FennecTabTray', 'FennecHistory', 'FennecSearchSettings', 'FennecPrivateBadge', 'FennecPrivateTabBadge']) {
    const svg = read(`browser/Reynard/Resources/Assets.xcassets/${asset}.imageset/icon.svg`);
    assert.match(svg, /Mozilla Public License/);
    assert.match(svg, /FIREFOX-ANDROID_158_0_RELEASE/);
    assert.match(svg, /<path/);
  }
});

test('private homepage return uses a mask not a white fox square and has a real help link', () => {
  const home = read(ui + 'Homepage/HomepageRootViewController.swift');
  assert.match(home, /normal\.setImage\(FennecTheme\.privateBrowsingImage/);
  assert.match(home, /privateBackground\.isHidden = !isPrivateBrowsing/);
  assert.match(home, /support\.mozilla\.org\/kb\/common-myths-about-private-browsing/);
  const section = read(ui + 'Homepage/Sections/PrivateBrowsing/PrivateBrowsingSectionViewController.swift');
  assert.match(section, /UIImage\(named: "FennecPrivateBadge"\)/);
  assert.match(section, /learn\.onTap = .*onLearnMore/);
});

test('unsupported capture experiments are isolated from live Gecko and cannot be mistaken for privacy enablement', () => {
  const experiment = read(ui + 'Appearance/FennecSecureCanvasExperiment.swift');
  assert.match(experiment, /responds\(to: selector\)/);
  assert.match(experiment, /unsupported|Unsupported/);
  for (const file of ['BrowserViewController.swift', 'ContentView/WebContentView.swift', 'Chrome/BrowserChrome.swift']) {
    assert.doesNotMatch(read(ui + file), /FennecSecureCanvasExperiment|disableUpdateMask/);
  }
  const diagnostic = read(ui + 'Appearance/FennecCaptureProbeViewController.swift');
  assert.match(diagnostic, /This does not protect browser tabs/);
  assert.match(read(ui + 'Library/Settings/Sections/Advanced/Developer/DeveloperPreferencesViewController.swift'), /pushViewController\(FennecCaptureProbeViewController\(\), animated: false\)/);
});
