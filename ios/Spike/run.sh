#!/bin/bash
# Build, install and launch the RealityKit spike (GPS card 1) on an iPhone 17 simulator; optional screenshot.
# Usage: ./run.sh [out.png]      Env: WAIT=seconds before the screenshot (default 3), SIM=<device id>
set -e
OUT="$1"; [ -n "$OUT" ] && OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
cd "$(dirname "$0")/.."
SIM="${SIM:-A6226E77-4321-425A-A537-3A955E4C32A7}"
BUNDLE="com.saqlainmomin.polymath.spike"
xcodegen generate >/dev/null
xcodebuild -project Polymath.xcodeproj -target PolymathSpike -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO SYMROOT="$PWD/build/products" build 2>&1 | grep -E "error: |\*\* BUILD" || true
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1
xcrun simctl terminate "$SIM" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM" build/products/Debug-iphonesimulator/PolymathSpike.app
xcrun simctl launch "$SIM" "$BUNDLE" >/dev/null
if [ -n "$OUT" ]; then sleep "${WAIT:-3}"; mkdir -p "$(dirname "$OUT")"; xcrun simctl io "$SIM" screenshot "$OUT" 2>&1 | tail -1; fi
