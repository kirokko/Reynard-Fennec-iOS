#!/usr/bin/env bash
# UIKit-only first-frame smoke test; uses real root/summary with mocked sections.
# Does not exercise Gecko, SideStore signing, helper extensions or JIT.
set -euo pipefail
cd "$(dirname "$0")/.."
work="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/ieynec-layout-smoke"
mkdir -p "$work"
xcrun simctl list devices available --json > "$work/devices.json"
device=$(node - "$work/devices.json" <<'NODE'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
for (const [runtime, devices] of Object.entries(data.devices).reverse()) {
  if (!runtime.includes('.iOS-')) continue;
  const phone = devices.find(d => d.isAvailable && d.name.startsWith('iPhone'));
  if (phone) { console.log(phone.udid); break; }
}
NODE
)
if [[ -z "$device" ]]; then
  echo '::error::No installed iOS Simulator runtime; cannot validate UIKit regressions.'
  exit 1
fi
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
app="$work/LayoutSmoke.app"
mkdir -p "$app"
cat > "$app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.ieynec.LayoutSmoke</string>
<key>CFBundleExecutable</key><string>LayoutSmoke</string>
<key>CFBundleName</key><string>LayoutSmoke</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>17.0</string>
<key>UILaunchScreen</key><dict/>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
</dict></plist>
PLIST
ui=browser/Reynard/Client/Interface
xcrun swiftc -sdk "$sdk" -target "$(uname -m)-apple-ios17.0-simulator" \
  tests/ui-layout-smoke/App.swift tests/ui-layout-smoke/TrayFixtures.swift \
  "$ui/Appearance/FennecTheme.swift" \
  "$ui/Chrome/FennecMenuViewController.swift" \
  "$ui/Homepage/Sections/HomepageSection.swift" \
  "$ui/Homepage/FennecHomepageSummaryView.swift" \
  "$ui/Homepage/HomepageRootViewController.swift" \
  "$ui/TabOverview/TabOverviewPresentation.swift" \
  "$ui/TabOverview/TabOverviewToolbar/TabOverviewTopToolbar.swift" \
  "$ui/TabOverview/TabOverviewClearTabsMenu.swift" \
  "$ui/TabOverview/FennecTabGroupsViewController.swift" \
  "$ui/Library/Settings/SettingsTableViewController.swift" \
  "$ui/Library/Settings/SettingsTableViewCell.swift" \
  browser/Reynard/Client/Shared/ContentModalNavigationController.swift \
  browser/Reynard/Client/TabManagement/TabGroupStore.swift \
  -o "$app/LayoutSmoke"
cp browser/Reynard/Resources/Assets.xcassets/custom/taboverview/private.mode.icon.imageset/private.mode.icon.png "$app/"
cp browser/Reynard/Resources/Assets.xcassets/ieynec-logo.imageset/logo.png "$app/ieynec-logo.png"
codesign --force --sign - "$app"
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" local.ieynec.LayoutSmoke data)
rm -f "$container/Documents/layout-pass.txt" "$container/Documents/"*-ready "$container/Documents/"*-captured
mkdir -p "$work/screenshots"
xcrun simctl launch --terminate-running-process --stdout="$work/stdout.log" --stderr="$work/stderr.log" "$device" local.ieynec.LayoutSmoke
for ((i=0; i<180; i++)); do
  for stage in home groups; do
    if [[ -f "$container/Documents/$stage-ready" && ! -f "$container/Documents/$stage-captured" ]]; then
      xcrun simctl io "$device" screenshot "$work/screenshots/$stage-on-screen.png"
      touch "$container/Documents/$stage-captured"
    fi
  done
  if [[ -f "$container/Documents/layout-pass.txt" ]]; then
    cat "$container/Documents/layout-pass.txt"
    mkdir -p "$work/screenshots"
    cp "$container/Documents/"*.png "$work/screenshots/"
    xcrun simctl terminate "$device" local.ieynec.LayoutSmoke || true
    exit 0
  fi
  sleep 1
done
mkdir -p "$work/screenshots"
cp "$container/Documents/"*.png "$work/screenshots/" 2>/dev/null || true
echo '::error::UIKit layout host did not reach its first-frame/regression completion marker.'
tail -100 "$work/stderr.log" || true
tail -100 "$work/stdout.log" || true
xcrun simctl terminate "$device" local.ieynec.LayoutSmoke || true
exit 1
