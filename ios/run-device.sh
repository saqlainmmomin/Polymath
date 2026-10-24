#!/bin/bash
# Build, install and launch Polymath on the owner's physical iPhone (automatic signing, free or paid team).
# Usage: ./run-device.sh [topic-id|-] [card-number|-]     Env: DEVICE=<devicectl identifier or name>, EXTRA="--index"
# Team id: ios/.team (gitignored, one line) or env TEAM. Needs Xcode signed into an Apple ID (Xcode > Settings > Accounts).
set -e
cd "$(dirname "$0")"
BUNDLE="com.saqlainmomin.polymath"
DEVICE="${DEVICE:-00008120-001A7188026BC01E}"   # Saqlain's iphone (list: xcrun devicectl list devices)
TEAM="${TEAM:-$(cat .team 2>/dev/null)}"
[ -n "$TEAM" ] || { echo "No team id: put it in ios/.team or set TEAM=<id>"; exit 1; }
TOPIC="$1"; CARD="$2"

state=$(xcrun devicectl list devices 2>/dev/null | grep -F "$DEVICE" | head -1)
case "$state" in *unavailable*|"") echo "iPhone not available. Plug it in by cable, unlock it, tap Trust, enable Developer Mode, keep it unlocked."; exit 2;; esac

[ -d Polymath.xcodeproj ] || xcodegen generate >/dev/null
node ../tools/export-topics.mjs >/dev/null
xcodebuild -project Polymath.xcodeproj -target Polymath -sdk iphoneos -configuration Debug \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic \
  SYMROOT="$PWD/build/device" build 2>&1 | grep -E "error: |\*\* BUILD" | tee build/device-build.log || true
grep -q "BUILD SUCCEEDED" build/device-build.log || { echo "Build failed (see above). Signing errors: open Xcode > Settings > Accounts and sign in again."; exit 3; }

APP="build/device/Debug-iphoneos/Polymath.app"
xcrun devicectl device install app --device "$DEVICE" "$APP"
ARGS=(); [ -n "$TOPIC" ] && [ "$TOPIC" != "-" ] && ARGS+=(--topic "$TOPIC"); [ -n "$CARD" ] && [ "$CARD" != "-" ] && ARGS+=(--card "$CARD"); [ -n "$EXTRA" ] && ARGS+=($EXTRA)
out=$(xcrun devicectl device process launch --device "$DEVICE" --terminate-existing "$BUNDLE" "${ARGS[@]}" 2>&1) && { echo "$out" | tail -2; echo "Launched."; exit 0; }
echo "$out" | tail -8
if echo "$out" | grep -qiE "invalid code signature|not been explicitly trusted|profile has not been|untrusted|integrity could not be verified"; then
  echo; echo "Trust the developer profile on the phone: Settings > General > VPN & Device Management > (your Apple ID) > Trust. Then run this script again."
elif echo "$out" | grep -qi "locked"; then echo "Unlock the phone and run again."; fi
exit 4
