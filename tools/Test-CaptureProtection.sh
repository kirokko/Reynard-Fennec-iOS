#!/usr/bin/env bash
# Isolated unsupported-secure-canvas experiment. Produces no installable IPA.
set -euo pipefail
cd "$(dirname "$0")/.."
work="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/ieynec-capture-probe"
mkdir -p "$work/screenshots"
app="$work/CaptureProbe.app"
mkdir -p "$app"
cat > "$app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.ieynec.CaptureProbe</string>
<key>CFBundleExecutable</key><string>CaptureProbe</string><key>CFBundleName</key><string>CaptureProbe</string>
<key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string><key>CFBundleDevelopmentRegion</key><string>en</string>
<key>MinimumOSVersion</key><string>17.0</string><key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/></dict></plist>
PLIST
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun swiftc -sdk "$sdk" -target "$(uname -m)-apple-ios17.0-simulator" tests/capture-protection/*.swift browser/Reynard/Client/Interface/Appearance/FennecSecureCanvasExperiment.swift -o "$app/CaptureProbe"
codesign --force --sign - "$app"
xcrun simctl list devices available --json > "$work/devices.json"
device=$(node - "$work/devices.json" <<'NODE'
const fs = require('fs');
for (const [runtime, devices] of Object.entries(JSON.parse(fs.readFileSync(process.argv[2])).devices).reverse()) {
  if (!runtime.includes('.iOS-')) continue;
  const d = devices.find(d => d.isAvailable && d.name.startsWith('iPhone'));
  if (d) { console.log(d.udid); break; }
}
NODE
)
test -n "$device"
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" local.ieynec.CaptureProbe data)
mkdir -p "$container/Documents"
rm -f "$container/Documents/"*-ready "$container/Documents/"*-captured "$container/Documents/probe-done"
video_pid=''
cleanup() {
  if [[ -n "$video_pid" ]]; then kill -INT "$video_pid" 2>/dev/null || true; wait "$video_pid" 2>/dev/null || true; fi
  cp "$work/stdout.log" "$work/stderr.log" "$work/screenshots/" 2>/dev/null || true
  cp "$container/Documents/"*.png "$container/Documents/"*.json "$work/screenshots/" 2>/dev/null || true
}
trap cleanup EXIT
xcrun simctl io "$device" recordVideo --codec=h264 "$work/screenshots/capture.mov" > "$work/video.log" 2>&1 &
video_pid=$!
xcrun simctl launch --terminate-running-process --stdout="$work/stdout.log" --stderr="$work/stderr.log" "$device" local.ieynec.CaptureProbe
for ((i=0;i<180;i++)); do
  for stage in normal protected layer-flag restored; do
    if [[ -f "$container/Documents/$stage-ready" && ! -f "$container/Documents/$stage-captured" ]]; then
      sleep 1
      xcrun simctl io "$device" screenshot "$work/screenshots/$stage-screen.png"
      sleep 1
      touch "$container/Documents/$stage-captured"
    fi
  done
  if [[ -f "$container/Documents/probe-done" ]]; then
    cp "$container/Documents/report.json" "$work/screenshots/"
    echo 'Probe finished. Images are evidence, NOT an automatic protection PASS.'
    exit 0
  fi
  sleep 1
done
echo '::error::Capture probe did not finish.'
exit 1
