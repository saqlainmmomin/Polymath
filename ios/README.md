# Polymath for iOS (wireframe)

A SwiftUI app that has the real structure and the real content of the web build, with each picture shown as a labelled placeholder. Purpose: judge navigation, card anatomy, spacing and the interaction cue on a real iPhone screen before porting any visuals. Direction and decisions: `tasks/direction-ios-option5.md`, `tasks/todo.md` (Phase 4).

## Run it
```
brew install xcodegen          # once
cd ios && xcodegen generate    # creates Polymath.xcodeproj from project.yml (not committed)
open Polymath.xcodeproj        # then pick an iPhone simulator and Run
```
Headless (build, install, launch on an iPhone 17 simulator, screenshot):
`./run.sh [topic-id|-] [card-number|-] [out.png] [light|dark]`, for example `./run.sh car-engine 2 wireframe/x.png dark`. Env: `WAIT=<seconds>`, `EXTRA="--index"`, `SIM=<device id>`.
Launch arguments the app understands: `--topic <id>`, `--card <n>` (1-based), `--index`.

## Run on your iPhone
One command once set up: `cd ios && ./run-device.sh [topic-id|-] [card-number|-]` (builds for the phone with automatic signing, installs, launches).
One-time setup:
1. Xcode > Settings > Accounts: be signed in to the Apple ID that owns your Personal Team (the signing certificate here is issued to saqlain.nmims@gmail.com). If the build says "login details were rejected", remove and re-add the account (the stored session expired).
2. Put the team id in `ios/.team` (one line, gitignored; Personal Team `6NSX84D3PB`), or pass `TEAM=<id>`. Find it in Xcode > Settings > Accounts > Team, or the OU of the Apple Development certificate.
3. Phone: plug in by cable, unlock, tap Trust This Computer, turn on Settings > Privacy & Security > Developer Mode (it restarts the phone), keep it unlocked while the script runs. `xcrun devicectl list devices` must show the phone as `connected` or `available`, not `unavailable`.
4. First launch: if it fails with an untrusted-developer error, on the phone go to Settings > General > VPN & Device Management > your Apple ID > Trust, then run the script again.
Free Apple ID limits: the profile expires after 7 days (run the script again to renew), and the bundle id must be unique to your team; if signing says `com.saqlainmomin.polymath` is taken, change it in `project.yml` and `run-device.sh`.
The device build uses the iphoneos SDK with `-target`, so it does not need the iOS 26.5 simulator platform. That platform is only needed for scheme-based builds, Xcode's Run button and tests (Xcode > Settings > Components, or `xcodebuild -downloadPlatform iOS`).

## Topics
Topic files in `../topics/*.js` stay the source of truth. `node ../tools/export-topics.mjs` (run by `run.sh`) writes `Polymath/Resources/topics.json`, which the app reads. Add a topic to `LIBRARY` in `../build.mjs` and it appears here after the next export.

## What is real, what is a placeholder
Real: the feed (swipe up = next topic, sideways = next card), card anatomy (headline above, picture panel fills, paragraph below; card 1 = the topic question at 33pt), small orientation title on later cards, page dots with the "Swipe" nudge, guess and "Go deeper" cards, Index sheet, light/dark tokens, the interaction cue (same timing as web: in after 0.7s, away after about 6s or on first touch, off for the session once any picture is touched).
Placeholder: every picture (shows its type, cycles its step notes, lists its labels). System serif and monospaced fonts stand in for Newsreader and IBM Plex Mono. No app icon. Bundle id `com.saqlainmomin.polymath` is a placeholder.

## Screens
`wireframe/`: 01 opener, 02 card with the cue, 03 opener in dark mode, 04 Go deeper, 05 Index.

## Xcode versions (checked 2026-10-24)
macOS 26.3.1, Xcode 26.6. The simulator runtime installed was iOS 26.4 while Xcode 26.6 wants the iOS 26.5 platform: building with `-target`/`run.sh` works on the 26.4 runtime, but scheme-based destinations (Xcode's Run button and test runs) may not list a simulator until the iOS 26.5 platform is installed (Xcode > Settings > Components).
