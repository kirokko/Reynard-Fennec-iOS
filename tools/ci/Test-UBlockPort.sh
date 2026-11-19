#!/usr/bin/env bash
# GPL-3.0-or-later. Unofficial full-uBO port experiment; DOES NOT create an IPA.
set -euo pipefail
cd "$(dirname "$0")/../.."
work=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/reynard-ubo-port.XXXXXX")
results="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/reynard-ubo-port-results"
mkdir -p "$results"
exec > >(tee "$results/build.log") 2>&1
xcodebuild -version > "$results/toolchain.txt"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
ios_sdk=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun --sdk iphoneos --show-sdk-version >> "$results/toolchain.txt"
xcrun simctl list devices available --json > "$results/devices.json"
app="$work/UBlockPortProbe.app"
mkdir -p "$app"
url=$(node -p "require('./tests/webkit-smoke/ublock-package.json').url")
curl --fail --location --retry 2 --max-time 120 "$url" -o "$work/upstream.xpi"
python3 tools/ublock/prepare.py "$work/upstream.xpi" "$app/ubo" > "$results/provenance.json"
node tools/ublock/test-compiler.mjs "$app/ubo" "$results"
python3 - "$app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'wb') as file:
    plistlib.dump(dict(CFBundleIdentifier='local.reynard.UBlockPortProbe',
        CFBundleExecutable='UBlockPortProbe', CFBundleName='uBO port research',
        CFBundlePackageType='APPL', CFBundleVersion='1', CFBundleShortVersionString='0.1',
        MinimumOSVersion='18.4', UILaunchScreen={}, UIDeviceFamily=[1],
        NSAppTransportSecurity={'NSAllowsLocalNetworking': True}), file)
PY
xcrun --sdk iphoneos clang -fobjc-arc -fmodules -isysroot "$ios_sdk" -target arm64-apple-ios18.4 \
  -c tests/webkit-smoke/UBlockPortProbe.m -o "$work/UBlockPortProbe-arm64.o"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -isysroot "$sdk" \
  -target "$(uname -m)-apple-ios18.4-simulator" -framework UIKit -framework WebKit \
  tests/webkit-smoke/UBlockPortProbe.m -o "$app/UBlockPortProbe"
device=$(node - "$results/devices.json" <<'NODE'
const fs = require('node:fs');
for (const [runtime, devices] of Object.entries(JSON.parse(fs.readFileSync(process.argv[2])).devices).reverse()) {
  if (!runtime.includes('.iOS-')) continue;
  const device = devices.find(d => d.isAvailable && d.name.startsWith('iPhone'));
  if (device) { console.log(device.udid); break; }
}
NODE
)
[[ -n "$device" ]] || { echo 'No iPhone Simulator'; exit 1; }
xcrun simctl boot "$device" > "$results/boot.log" 2>&1 || true
python3 tests/webkit-smoke/server.py > "$results/server.log" 2>&1 &
server_pid=$!
cleanup() {
  kill "$server_pid" 2>/dev/null || true
  xcrun simctl terminate "$device" local.reynard.UBlockPortProbe >/dev/null 2>&1 || true
}
trap cleanup EXIT
for attempt in {1..30}; do
  if curl --fail -s http://127.0.0.1:8765/port/index.html > /dev/null; then break; fi
  sleep 1
done
xcrun simctl bootstatus "$device" -b
codesign --force --sign - "$app"
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" local.reynard.UBlockPortProbe data)
xcrun simctl launch --terminate-running-process --stdout="$results/native.stdout.log" \
  --stderr="$results/native.stderr.log" "$device" local.reynard.UBlockPortProbe
for attempt in {1..130}; do
  [[ ! -f "$container/Documents/result.json" ]] || break
  sleep 1
done
[[ -f "$container/Documents/result.json" ]] || { echo 'Native probe did not produce a report'; exit 1; }
cp "$container/Documents/result.json" "$results/UBlockPortProbe.json"
[[ ! -f "$container/Documents/popup.png" ]] || cp "$container/Documents/popup.png" "$results/"
node - "$results" <<'NODE'
const fs = require('node:fs');
const dir = process.argv[2];
const result = JSON.parse(fs.readFileSync(`${dir}/UBlockPortProbe.json`));
console.log(JSON.stringify(result, null, 2));
const n = result.network || {};
const blocked = ['blocked', 'important', 'xhr-only', 'image:image-only.txt'];
const allowed = ['control', 'allowed', 'image-only', 'new-rule', 'image:control.png'];
const verdict = {
  staticNetworkPassed: blocked.every(k=>n[k]?.loaded === false) && allowed.every(k=>n[k]?.loaded === true),
  atomicRejectionPassed: result.transaction?.rejected === true && result.transaction?.oldRulesUnchanged === true,
  storageRuleUpdatePassed: result.update?.storageChangeApplied === true && result.updatedFetch?.loaded === false,
  originalBackgroundReady: result.port?.upstream?.stage === 'ready',
  originalCosmeticPassed: result.content?.cosmeticDisplay === 'none',
  originalScriptletPassed: result.content?.scriptletObserved === true,
  originalPopupRenderedVersion: result.originalPopup?.version?.includes('1.76.4') === true,
  fullUBlockOriginVerified: false, sideStoreVerified: false,
  note: 'Prototype only. Passing DNR fixtures does not imply full Firefox uBO compatibility. No IPA/release.',
};
fs.writeFileSync(`${dir}/port-verdict.json`, JSON.stringify(verdict, null, 2));
console.log(JSON.stringify(verdict, null, 2));
if (!verdict.originalBackgroundReady || !verdict.originalCosmeticPassed || !verdict.originalScriptletPassed || !verdict.originalPopupRenderedVersion)
  console.log('::warning::Original full-uBO startup/content/UI paths did not all pass. Read raw errors; do not label full compatibility.');
if (!verdict.staticNetworkPassed || !verdict.atomicRejectionPassed || !verdict.storageRuleUpdatePassed)
  throw new Error('Full-uBO native DNR port prerequisites failed; see raw report');
NODE
