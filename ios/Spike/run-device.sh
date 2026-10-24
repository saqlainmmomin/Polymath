#!/bin/bash
# Build, install and launch the RealityKit spike on the owner's iPhone. Env: DEVICE=<id>, TEAM=<id> (default ios/.team)
set -e
cd "$(dirname "$0")/.."
BUNDLE="com.saqlainmomin.polymath.spike"
DEVICE="${DEVICE:-00008120-001A7188026BC01E}"
TEAM="${TEAM:-$(cat .team 2>/dev/null)}"
[ -n "$TEAM" ] || { echo "No team id: put it in ios/.team or set TEAM=<id>"; exit 1; }
state=$(xcrun devicectl list devices 2>/dev/null | grep -F "$DEVICE" | head -1)
case "$state" in *unavailable*|"") echo "iPhone not available. Plug it in, unlock it, trust, enable Developer Mode."; exit 2;; esac
xcodegen generate >/dev/null
mkdir -p build
xcodebuild -project Polymath.xcodeproj -target PolymathSpike -sdk iphoneos -configuration Debug \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic \
  SYMROOT="$PWD/build/device" build 2>&1 | grep -E "error: |\*\* BUILD" | tee build/spike-device-build.log || true
grep -q "BUILD SUCCEEDED" build/spike-device-build.log || { echo "Build failed (see above)."; exit 3; }
xcrun devicectl device install app --device "$DEVICE" build/device/Debug-iphoneos/PolymathSpike.app
out=$(xcrun devicectl device process launch --device "$DEVICE" --terminate-existing "$BUNDLE" 2>&1) && { echo "$out" | tail -2; echo "Launched."; exit 0; }
echo "$out" | tail -8
if echo "$out" | grep -qiE "invalid code signature|not been explicitly trusted|profile has not been|untrusted"; then echo "Trust the developer profile: Settings > General > VPN & Device Management."; elif echo "$out" | grep -qi locked; then echo "Unlock the phone and run again."; fi
exit 4
