#!/bin/bash
# Build + screenshot each GPS card at several moments: ./shoot.sh  -> Spike/shots/cardN-<sec>s.png
cd "$(dirname "$0")/.."
SIM="${SIM:-A6226E77-4321-425A-A537-3A955E4C32A7}"; B=com.saqlainmomin.polymath.spike
xcodegen generate >/dev/null
xcodebuild -project Polymath.xcodeproj -target PolymathSpike -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO SYMROOT="$PWD/build/products" build 2>&1 | grep -E "error: |\*\* BUILD" | sort -u
xcrun simctl boot "$SIM" 2>/dev/null; xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1
xcrun simctl install "$SIM" build/products/Debug-iphonesimulator/PolymathSpike.app
mkdir -p Spike/shots
for c in ${CARDS:-1 2 3 4 5}; do
  xcrun simctl terminate "$SIM" $B 2>/dev/null; xcrun simctl launch "$SIM" $B --topic gps --card $c >/dev/null
  prev=0
  for s in ${TIMES:-1 3 5 7}; do sleep $((s-prev)); prev=$s; xcrun simctl io "$SIM" screenshot Spike/shots/card$c-${s}s.png 2>/dev/null; done
done
