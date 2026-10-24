import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const read = p => fs.readFileSync(new URL('../' + p, import.meta.url), 'utf8');
const ui = 'browser/Reynard/Client/Interface/';

test('private gate uses system authentication, process-only state and never exposes cancellation', () => {
  const shield = read(ui + 'Appearance/FennecPrivacyShield.swift');
  const state = read('browser/Reynard/Client/Preferences/FennecPrivateAccessState.swift');
  assert.match(state, /private\(set\) var isUnlocked = false/);
  assert.match(state, /if success \{ isUnlocked = true \}/);
  assert.doesNotMatch(state + shield, /UserDefaults|Keychain|isSecureTextEntry|disableUpdateMask/);
  assert.match(shield, /canEvaluatePolicy\(\.deviceOwnerAuthentication/);
  assert.match(shield, /evaluatePolicy\(\.deviceOwnerAuthentication/);
  assert.match(shield, /authenticationFinished\(success: success\)/);
  assert.match(shield, /windowLevel = \.alert \+ 1/);
  assert.match(shield, /accessibilityViewIsModal = true/);
  assert.match(shield, /cover\?\.makeKey\(\)/);
  assert.match(shield, /previousKeyWindow\?\.endEditing\(true\)/);
  assert.match(shield, /showFailure\(\)/);
  const scene = read('browser/Reynard/SceneDelegate.swift');
  assert.match(scene, /installPrivateAccessGates\(in: browserViewController, scene: windowScene\)\s*window.makeKeyAndVisible/);
  assert.match(scene, /for child in controller.children/);
  const browser = read(ui + 'BrowserViewController.swift');
  assert.match(browser, /privacyShield.onReturnToRegular/);
  const plist = read('browser/Reynard/Resources/Info.plist');
  assert.match(plist, /NSFaceIDUsageDescription/);
});

test('Android-style search pill and solid private background replace long prompt and glow', () => {
  const bar = read(ui + 'Chrome/AddressBar/AddressBar.swift');
  assert.match(bar, /placeholderText = FennecTheme.text\("Search"\)/);
  assert.match(bar, /leadingButton == \.search \? 48/);
  assert.match(bar, /leadingButton.heightAnchor.constraint\(equalToConstant: 36\)/);
  const theme = read(ui + 'Appearance/FennecTheme.swift');
  assert.doesNotMatch(theme, /CAGradientLayer|\.radial/);
  assert.match(theme, /backgroundColor = FennecTheme.privateSurface/);
});

test('real AddressBar is compiled and captured so provider art cannot inflate unnoticed', () => {
  const script = read('tools/Test-HomepageLayout.sh');
  for (const source of ['AddressBar.swift', 'AddressBarButton.swift', 'AddressBarDismissButton.swift', 'AddressBarMenu.swift', 'AddressBarFixtures.swift']) assert.ok(script.includes(source));
  assert.doesNotMatch(read('tests/ui-layout-smoke/ChromeFixtures.swift'), /class AddressBar:/);
  assert.match(script, /for stage in private home addressbar groups/);
  const fixture = read('tests/ui-layout-smoke/AddressBarFixtures.swift');
  assert.match(fixture, /button.imageView!.bounds.size == CGSize\(width: 48, height: 36\)/);
  assert.match(fixture, /field.font\?\.pointSize == 16/);
  const bar = read(ui + 'Chrome/AddressBar/AddressBar.swift');
  assert.match(bar, /contentHorizontalAlignment = state == \.search \? \.center : \.fill/);
  assert.match(bar, /UIGraphicsImageRenderer\(size: CGSize\(width: 48, height: 36\)\)/);
  assert.match(bar, /CGRect\(x: 8, y: 7, width: 22, height: 22\)/);
  assert.match(bar, /\.foregroundColor: FennecTheme.searchHint/);
});

test('audio control is hidden and restored tabs default to browser-unmuted', () => {
  assert.match(read(ui + 'Chrome/AddressBar/AddressBar.swift'), /secondaryTrailingButton: \.hidden/);
  assert.match(read(ui + 'BrowserViewController+AddressBar.swift'), /updateAddressBarAudioButton\(isVisible: false, isMuted: false\)/);
  const manager = read('browser/Reynard/Client/TabManagement/TabManagerImpl.swift');
  assert.doesNotMatch(manager, /isMuted: snapshot.isMuted/);
  assert.match(manager, /isMuted: false,\s*isPrivate: true/);
  assert.match(manager, /isMuted: false,\s*isPrivate: false/);
});

test('Apple product autoplay uses Gecko blockAll permission, not global animation removal', () => {
  const store = read('browser/Reynard/Client/Stores/SitePermissionStore.swift');
  assert.match(store, /permission == \.autoplay && FennecMediaPolicy.blocksAutomaticMedia\(on: host\)/);
  assert.match(store, /case \.blocked:\s*return ContentPermission.Value.blockAll.rawValue/);
  const coordinator = read('browser/Reynard/Client/SessionManagement/Coordinators/PermissionCoordinator.swift');
  assert.match(coordinator, /permission == \.autoplay[\s\S]*rawValue: action.autoplayValue/);
  assert.match(coordinator, /sitePermission == \.autoplay[\s\S]*action.autoplayValue/);
  assert.doesNotMatch(read('browser/Reynard/Client/Preferences/RuntimePreferences.swift'), /image.animation_mode|prefersReducedMotion|media.autoplay/);
});
