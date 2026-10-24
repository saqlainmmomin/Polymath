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

## Topics
Topic files in `../topics/*.js` stay the source of truth. `node ../tools/export-topics.mjs` (run by `run.sh`) writes `Polymath/Resources/topics.json`, which the app reads. Add a topic to `LIBRARY` in `../build.mjs` and it appears here after the next export.

## What is real, what is a placeholder
Real: the feed (swipe up = next topic, sideways = next card), card anatomy (headline above, picture panel fills, paragraph below; card 1 = the topic question at 33pt), small orientation title on later cards, page dots with the "Swipe" nudge, guess and "Go deeper" cards, Index sheet, light/dark tokens, the interaction cue (same timing as web: in after 0.7s, away after about 6s or on first touch, off for the session once any picture is touched).
Placeholder: every picture (shows its type, cycles its step notes, lists its labels). System serif and monospaced fonts stand in for Newsreader and IBM Plex Mono. No app icon. Bundle id `com.saqlainmomin.polymath` is a placeholder.

## Screens
`wireframe/`: 01 opener, 02 card with the cue, 03 opener in dark mode, 04 Go deeper, 05 Index.

## Xcode versions (checked 2026-10-24)
macOS 26.3.1, Xcode 26.6. The simulator runtime installed was iOS 26.4 while Xcode 26.6 wants the iOS 26.5 platform: building with `-target`/`run.sh` works on the 26.4 runtime, but scheme-based destinations (Xcode's Run button and test runs) may not list a simulator until the iOS 26.5 platform is installed (Xcode > Settings > Components).
