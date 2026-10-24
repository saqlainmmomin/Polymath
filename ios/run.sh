#!/bin/bash
# Build, install and launch Polymath on an iPhone 17 simulator, optionally on a given topic/card, and save a screenshot.
# Usage: ./run.sh [topic-id|-] [card-number|-] [out.png] [light|dark]      e.g. ./run.sh car-engine 3 wireframe/engine-3.png dark
# Env: WAIT=seconds before the screenshot (default 3), EXTRA="--index" for more launch arguments, SIM=<device id>.
set -e
cd "$(dirname "$0")"
SIM="${SIM:-A6226E77-4321-425A-A537-3A955E4C32A7}"   # iPhone 17 (list yours with: xcrun simctl list devices available)
TOPIC="$1"; CARD="$2"; OUT="${3:-}"; MODE="${4:-light}"
[ -d Polymath.xcodeproj ] || xcodegen generate >/dev/null
node ../tools/export-topics.mjs >/dev/null
xcodebuild -project Polymath.xcodeproj -target Polymath -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO SYMROOT="$PWD/build/products" build 2>&1 | grep -E "error: |\*\* BUILD" || true
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1
xcrun simctl ui "$SIM" appearance "$MODE"
xcrun simctl terminate "$SIM" com.saqlainmomin.polymath 2>/dev/null || true
xcrun simctl install "$SIM" build/products/Debug-iphonesimulator/Polymath.app
ARGS=(); [ -n "$TOPIC" ] && [ "$TOPIC" != "-" ] && ARGS+=(--topic "$TOPIC"); [ -n "$CARD" ] && [ "$CARD" != "-" ] && ARGS+=(--card "$CARD"); [ -n "$EXTRA" ] && ARGS+=($EXTRA)
xcrun simctl launch "$SIM" com.saqlainmomin.polymath "${ARGS[@]}" >/dev/null
if [ -n "$OUT" ]; then sleep "${WAIT:-3}"; mkdir -p "$(dirname "$OUT")"; xcrun simctl io "$SIM" screenshot "$OUT" 2>&1 | tail -1; fi
