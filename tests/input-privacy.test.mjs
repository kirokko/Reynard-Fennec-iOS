import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
const root = new URL('../', import.meta.url);
const read = p => fs.readFileSync(new URL(p, root), 'utf8');
const ui = 'browser/Reynard/Client/Interface/';

test('private homepage retains an actionable return switch without deleting tabs', () => {
  const home = read(ui + 'Homepage/HomepageRootViewController.swift');
  assert.match(home, /if folder == nil && isPrivateBrowsing/);
  assert.match(home, /homepage\.returnToNormal/);
  assert.match(home, /normal\.onTap = .*onPrivateTab/);
  const actions = read(ui + 'BrowserViewController+ContentOverlay.swift');
  assert.match(actions, /selectedTabMode == \.private[\s\S]*selectTab\(at: index, mode: \.regular\)/);
  assert.match(actions, /homepageReturnTabID = tabManager\.selectedTab\?\.id/);
});

test('marked text cannot be hidden by asynchronous autocomplete or replaced by focus preview', () => {
  const field = read(ui + 'Chrome/AddressBar/AddressBarTextField.swift');
  assert.match(field, /onWillSetMarkedText\?\(\)\s*super\.setMarkedText/);
  const bar = read(ui + 'Chrome/AddressBar/AddressBar.swift');
  assert.match(bar, /onWillSetMarkedText = .*clearAutocomplete/);
  assert.match(bar, /guard textField\.isFirstResponder, textField\.markedTextRange == nil/);
  assert.match(bar, /guard isEditingText, textField\.markedTextRange == nil/);
  assert.match(bar, /if textField\.markedTextRange != nil \{\s*clearAutocomplete\(\)/);
});

test('search picker routes real supported engines without changing saved defaults', () => {
  const bar = read(ui + 'Chrome/AddressBar/AddressBar.swift');
  assert.match(bar, /oneOffSearchEngine: SearchEngine\?/);
  assert.match(bar, /searchEnginePickerImage\(\)/);
  assert.match(bar, /chevron.down/);
  assert.doesNotMatch(bar, /Prefs\.SearchSettings\.searchEngine\s*=/);
  const actions = read(ui + 'BrowserViewController+AddressBar.swift');
  assert.match(actions, /SearchEngine\.allCases\.filter/);
  assert.match(actions, /SearchEngine\.destination\(for: query, engine: engine\)/);
  assert.match(actions, /presentContentModal\(SearchPreferencesViewController\(\)\)/);
  for (const engine of ['yahoo', 'bing', 'brave', 'duckDuckGo', 'ecosia', 'startpage']) {
    const dir = `browser/Reynard/Resources/Assets.xcassets/FennecSearch-${engine}.imageset/`;
    assert.equal(JSON.parse(read(dir + 'Contents.json')).images[0].filename, 'icon.png');
    const png = fs.readFileSync(new URL(dir + 'icon.png', root));
    assert.equal(png.subarray(1, 4).toString(), 'PNG');
  }
});

test('keyboard docking cancels old layer transforms and resets on lost focus', () => {
  const toolbar = read(ui + 'Chrome/Toolbar/BottomToolbar.swift');
  assert.match(toolbar, /CATransaction\.setDisableActions\(true\)/);
  assert.match(toolbar, /contentView\.layer\.removeAllAnimations\(\)/);
  assert.match(toolbar, /backgroundView\.layer\.removeAllAnimations\(\)/);
  assert.match(read(ui + 'Search/SearchOverlayCoordinator.swift'), /searchChrome\.dockAddressBar\(offset: 0\)/);
});

test('capture shield uses public capture/lifecycle signals and does not claim screenshot prevention', () => {
  const shield = read(ui + 'Appearance/FennecPrivacyShield.swift');
  assert.match(shield, /UIScreen\.capturedDidChangeNotification/);
  assert.match(shield, /UIScene\.willDeactivateNotification/);
  assert.match(shield, /UIScreen|scene\.screen\.isCaptured/);
  assert.match(shield, /window\.windowLevel = \.alert \+ 1/);
  assert.doesNotMatch(shield, /NSClassFromString|NSSelectorFromString|isSecureTextEntry/);
  const browser = read(ui + 'BrowserViewController.swift');
  assert.match(browser, /tabOverview\.isPresented && self\.tabOverview\.mode == \.privateTabs/);
  assert.match(read(ui + 'TabOverview/TabOverview.swift'), /onPrivacyModeChanged\?\(\)/);
});
