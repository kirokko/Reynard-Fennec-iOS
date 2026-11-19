#!/usr/bin/env bash
# GPL-3.0. Independent migration gate. Does NOT build/deliver the browser IPA.
set -euo pipefail
cd "$(dirname "$0")/../.."
work="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/reynard-webkit-smoke"
mkdir -p "$work/results"
exec > >(tee "$work/results/build.log") 2>&1
xcodebuild -version > "$work/results/toolchain.txt"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
ios_sdk=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun --sdk iphoneos --show-sdk-version >> "$work/results/toolchain.txt"
# Preserve the ACTUAL selected Apple SDK declarations, not WebKit/main guesses.
for name in WKWebExtension WKWebExtensionContext WKWebExtensionController WKWebViewConfiguration; do
  cp "$ios_sdk/System/Library/Frameworks/WebKit.framework/Headers/$name.h" "$work/results/"
done
shasum -a 256 "$work/results/"*.h > "$work/results/headers.sha256"
# Compile both sources for physical iPhone architecture without Gecko, a
# provisioning profile, JIT entitlements, VPN, idevice or embedded engine SDK.
xcrun swiftc -sdk "$ios_sdk" -target arm64-apple-ios17.0 -emit-module \
  -module-name ReynardWebKitEngine browser/WebKitEngine/*.swift -o "$work/ReynardWebKitEngine.swiftmodule"
xcrun --sdk iphoneos clang -fobjc-arc -fmodules -isysroot "$ios_sdk" -target arm64-apple-ios18.4 \
  -c tests/webkit-smoke/Extensions.m -o "$work/Extensions-arm64.o"
xcrun simctl list devices available --json > "$work/devices.json"
device=$(node - "$work/devices.json" <<'NODE'
const fs = require('node:fs');
const devices = JSON.parse(fs.readFileSync(process.argv[2])).devices;
for (const [runtime, list] of Object.entries(devices).reverse()) {
  if (!runtime.includes('.iOS-')) continue;
  const phone = list.find(d => d.isAvailable && d.name.startsWith('iPhone'));
  if (phone) { console.log(phone.udid); break; }
}
NODE
)
[[ -n "$device" ]] || { echo 'No iOS Simulator available'; exit 1; }
xcrun simctl boot "$device" > "$work/results/boot.log" 2>&1 || true
python3 tests/webkit-smoke/server.py > "$work/results/server.log" 2>&1 &
server_pid=$!
cleanup() {
  kill "$server_pid" 2>/dev/null || true
  for id in local.reynard.WebKitSmoke local.reynard.ExtensionProbe; do
    xcrun simctl terminate "$device" "$id" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT
for attempt in {1..30}; do
  if curl --fail -s http://127.0.0.1:8765/one.html > /dev/null; then break; fi
  sleep 1
done
make_app() {
  local name=$1
  mkdir -p "$work/$name.app"
  /usr/libexec/PlistBuddy -c Clear "$work/$name.app/Info.plist" 2>/dev/null || true
  python3 - "$work/$name.app/Info.plist" "$name" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'wb') as file:
    plistlib.dump(dict(CFBundleIdentifier='local.reynard.' + sys.argv[2],
        CFBundleExecutable=sys.argv[2], CFBundleName=sys.argv[2],
        CFBundlePackageType='APPL', CFBundleVersion='1', CFBundleShortVersionString='1.0',
        MinimumOSVersion='18.4', UILaunchScreen={}, UIDeviceFamily=[1],
        NSAppTransportSecurity={'NSAllowsLocalNetworking': True}), file)
PY
}
make_app WebKitSmoke
xcrun swiftc -g -sdk "$sdk" -target "$(uname -m)-apple-ios18.4-simulator" \
  browser/WebKitEngine/*.swift tests/webkit-smoke/App.swift -o "$work/WebKitSmoke.app/WebKitSmoke"
make_app ExtensionProbe
for version in 2 3; do
  cp -R "tests/webkit-smoke/mv$version" "$work/ExtensionProbe.app/"
  cp tests/webkit-smoke/{background,content}.js "$work/ExtensionProbe.app/mv$version/"
done
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -isysroot "$sdk" \
  -target "$(uname -m)-apple-ios18.4-simulator" -framework UIKit -framework WebKit \
  tests/webkit-smoke/Extensions.m -o "$work/ExtensionProbe.app/ExtensionProbe"
xcrun simctl bootstatus "$device" -b
for name in WebKitSmoke ExtensionProbe; do
  codesign --force --sign - "$work/$name.app"
  xcrun simctl install "$device" "$work/$name.app"
  container=$(xcrun simctl get_app_container "$device" "local.reynard.$name" data)
  rm -f "$container/Documents/result.json"
  xcrun simctl launch --terminate-running-process --stdout="$work/results/$name.stdout.log" \
    --stderr="$work/results/$name.stderr.log" "$device" "local.reynard.$name"
  for attempt in {1..150}; do
    [[ ! -f "$container/Documents/result.json" ]] || break
    sleep 1
  done
  [[ -f "$container/Documents/result.json" ]] || { echo "$name timed out"; exit 1; }
  cp "$container/Documents/result.json" "$work/results/$name.json"
  xcrun simctl terminate "$device" "local.reynard.$name" || true
done
node - "$work/results" <<'NODE'
const fs = require('node:fs');
const dir = process.argv[2];
const core = JSON.parse(fs.readFileSync(`${dir}/WebKitSmoke.json`));
console.log(JSON.stringify(core, null, 2));
if (core.failures.length || core.passed.length < 18) throw new Error('WebKit integration failed');
const ext = JSON.parse(fs.readFileSync(`${dir}/ExtensionProbe.json`));
console.log(JSON.stringify(ext, null, 2));
// Native incompatibility is a recorded feasibility finding, not a browser pass.
const compatible = ext.results.every(item => {
  if (item.stage !== 'content-message-storage' || !item.unloaded) return false;
  const result = JSON.parse(item.result);
  return result.probe === 'native-roundtrip' && result.runtime === true && item.runtimeErrors === '(\n)';
});
fs.writeFileSync(`${dir}/extension-verdict.json`, JSON.stringify({
  fixturesPassed: compatible,
  sideStoreVerified: false, uBlockOriginVerified: false,
  note: 'Probe finding only. A green workflow does not assert extension compatibility.'
}, null, 2));
NODE
