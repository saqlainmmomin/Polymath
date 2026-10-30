# Tell Me How: direction and plan (agreed 2026-10-24)

Done earlier: the topic-format experiment (recipe + blocks + Sonnet agent) finished. Gearbox was about 90% usable as delivered; see `fix-log.md`.

## Direction
- **Positioning:** entertainment first, between education and entertainment. Never edtech: no scores, no quizzes, no lessons, no streaks.
- **Format = shorts.** Swipe up anywhere = a new random topic. Swipe sideways (or tap the right edge) = the next card in this topic. The last card has "Go deeper" links to related topics.
- **Topic size (revised 2026-10-24 after the owner tried v2):** one idea per topic, 2–4 cards plus `more`. Big subjects become a series of small topics linked through `more`. The 9-card engine and gearbox were too long: the gears explanation didn't land at all, and the ice bite did. (Earlier plan: 8–9 card full topics plus bites.)
- **Guess taps stay** as light, unscored taps before a reveal. The recall/quiz card and the score are removed.
- **Look** (inspired by makingsoftware.com and the "Gazette" editorial mockup): one reading voice and no competing hierarchy.
  - Type: one serif (e.g. Newsreader / Source Serif 4) for headlines and text, loose line height. Tiny uppercase mono only for diagram labels and the card counter. Drop Big Shoulders, the orange kickers and the MENTAL MODEL box.
  - Card: the visual takes the top ~55%, then a headline and at most 2 sentences. The takeaway is the last sentence, in bold.
  - Palette: warm off-white paper, near-black ink, one rust accent used only for "tap this" or "this is moving". Dark mode = ink paper, same rules.
  - Chrome: page dots at the bottom (current card in accent, "Swipe →" on card 1), text-link buttons. (Was a hairline progress bar and `03 / 08`.)
- **Visuals:** technical line art by default (thin ink lines, cutaways and exploded views, mono labels with leader lines, no captions, colour only for the subject). Other styles are allowed per topic when they explain that topic better; try them as experiments, not by default.
- **Motion:** slow, eased and mechanical. Animations start on their own when a card appears, loop calmly, and only the explaining part moves.
- **Animation-type library** (reusable, data in and no topic text in code), so most topics fill templates and only flagships get custom sims: process steps, cycle loop, scrubbable cutaway, before/after, flow along a path, lever/force, rotating mechanism (gears), scale zoom, labelled reveal diagram, wave/signal, network/map, timeline.
- **App:** Capacitor shell around the existing web build. Topics stay data files. Ship to TestFlight and Play internal testing.
- **Production line per topic (Sonnet agents):** writer (recipe + animation types) → separate newcomer reviewer → fact checker → phone-screen check (375px, light and dark). Saqlain reviews only the finished topic and the fix log.

## Phase 1: Pilot (before any new topics)
Status 2026-10-24: steps 1–5 done (spec in `tasks/pilot-spec.md`, v1 backup in `archive-v1-pre-pilot/`). Engine and gearbox are 9 cards each, ice-floats is a 2-card bite; all passed newcomer review + fact check after fixes (see `fix-log.md`). Step 6: testers' library link republished with v2 on 2026-10-24 (version 5); collect their feedback next.
1. Rewrite `RECIPE.md` for the new format: 8–9 cards at most or a 1–2 card bite, no recall card, the card anatomy above, the bold-takeaway rule, and the screen budget kept.
2. New look in `core/`: serif + mono fonts, warm paper tokens (light/dark), card layout with the visual on top, hairline chrome, and the mental-model box and kicker removed.
3. Shorts navigation: vertical = random topic, horizontal = cards within a topic, Go deeper links, bites in the feed.
4. Animation-type library: restyle the existing canvases to line art, then add the generic types above, starting with process steps, cutaway and flow (turbo and most topics need them). Document each in `core/BLOCKS.md`.
5. Rebuild engine and gearbox in the new format (8–9 cards at most each, depth moved into linked topics/bites) and write one bite.
6. Show the 5 testers; fix what they flag. Smoke test: 375px screenshots in light and dark, no console errors, both swipe directions work.

## Phase 1b: Small-topic rework (2026-10-24)
- Picture now grows to fill the space the text doesn't need (owner: text stuck under the picture with empty space below).
- Engine → engine-push, crank, four-strokes, cylinders. Gearbox → spanner, two-gears, why-gears. Old 9-card versions in `archive-v2-long/`.
- Then review, phone check, and owner OK before republishing the testers' link.

## Phase 1c: Titles, layout, dots, first non-machine topics (2026-10-24)
- Done: titles as hooks, picture ~50% with text right under it, page dots replace the counter and progress line, `spark` diagram style, 3 new topics (sky-blue, gps, card-payment), flow check in `tasks/flow-check.md`. Private preview republished.
- Next (owner to decide): space out series in the shuffle; watch for diagram step dots read as page dots; redo the card-payment timeline visual; keep new topics mostly non-machine. Testers' link not republished yet (needs owner OK).

## Phase 2: First 20 topics + test app
7. Capacitor wrapper; TestFlight + Play internal testing builds.
8. Run the production line until the feed holds about 20 topics (now all small, one idea each; series count as several), logging fixes in `fix-log.md`.
9. Ship the test build to testers. Signal to scale to 100: people keep swiping up for more topics.

### Draft topic list (4 themes)
- **Machines:** car engine*, gearbox*, how brakes stop a car, lock and key, how a fridge makes cold; bite: how a zip locks.
- **Nature & weather:** why the sky is blue, how lightning forms, how a rainbow forms; bites: why ice floats, why the sea is salty.
- **Internet & phones:** how Wi-Fi carries data, how GPS knows where you are, how a touchscreen feels your finger; bite: what a pixel is.
- **Money & everyday systems:** how a card payment goes through, how a barcode works, how airlines price seats; bites: why prices end in .99, how a cash machine knows your balance.
(* = rebuilt in Phase 1)

## Phase 3: Big questions, one card system, interaction cue (2026-10-24, owner direction)
Owner feedback: the small topics' questions do not spark curiosity; the big ones ("How does an engine work?") did. Wants bigger, eye-catching question titles, no dead space on cards, softer content, and a hint that animations can be touched.

**Decisions**
- Topic size: a topic is one BIG question, 4-6 cards at most (1-2 for a quick one). Engine series -> one topic, gears series -> one topic. Old small topics go to `archive-v3-small/`.
- Title = a full, natural question with a tension or stake ("Why does ice float on the very water it came from?"; titles must be literally true). Big serif, first thing on card 1.
- Card anatomy (3 zones, no dead space): headline ABOVE the picture, picture takes all spare height, 1 short paragraph below. Card 1 shows the topic question as its headline (bar title hidden there), later cards show a small version in the bar.
- Interaction cue: a small pill on the picture's bottom edge ("Drag the crank"), appears ~0.7s after the card shows, fades after ~5s or on first touch, and stops for the session once the reader has interacted anywhere.
- System, not one-offs: `RECIPE.md` v3 (sizing, title formula, copy rules with before/after), `topics/_template.js`, and lint warnings in `build.mjs` so every topic is checked the same way.

**Steps** (core first, then content in parallel)
1. [ ] Core: card anatomy v3 (CSS + `R.card`/`R.guess`), bar title rule, cue helper wired into crank/strokes/gears/cylinders/diagram.
2. [ ] `build.mjs` lint (title is a question, 1-6 cards, words per card, cue not disabled on interactive visuals) and `topics/_template.js`.
3. [ ] `RECIPE.md` v3 and `core/BLOCKS.md` updates.
4. [ ] Content, parallel writers + separate newcomer reviewer + fact checker: engine (merge 4 topics), gears (merge 3 topics), retitle/rewrite ice-floats, sky-blue, gps, card-payment.
5. [ ] Phone check light + dark, then owner review on the private preview. Testers' link stays untouched.
Later (owner): 10-15 new big-question topics, then the app shell.

## Phase 4: native iOS app "Polymath", wireframe first (2026-10-24, owner direction)
The product is now called **Polymath**. Target: native iOS app (hybrid visuals, see `tasks/direction-ios-option5.md`). Machine check: macOS 26.3.1, Xcode 26.6, iOS 26.4 simulator runtime + iPhone 17 simulators present, so building works now with no OS or Xcode update.

**This phase = a rough wireframe, not the product:** a SwiftUI app that has the real structure and the real content, with each picture shown as a labelled placeholder (visual type, its step notes cycling). The point is to judge navigation, card anatomy, spacing and the cue on a real iPhone-sized screen before porting any visuals.

Decisions (assumptions, owner can change)
- Location: `ios/` in this repo. Generated with XcodeGen (`ios/project.yml`); the `.xcodeproj` is not committed. Bundle id `com.saqlainmomin.polymath` (placeholder, change before TestFlight). Deployment target iOS 17.
- Topic data: the JS topic files stay the source of truth for now. `tools/export-topics.mjs` evaluates them (same sandbox as `build.mjs`) and writes `ios/Polymath/Resources/topics.json`; the app only reads JSON. Revisit when we stop writing topics in JS.
- Pictures: placeholders in this phase; first real native visual comes from the spike in the direction file (RealityKit GPS card 1). The other session owns that spike; it must live in its own folder (`ios/Spike*`) so the two do not collide.
- Fonts: system serif and monospaced for now; bundle Newsreader and IBM Plex Mono when we polish.

Steps
1. [x] Exporter + `topics.json` (6 topics, 32 cards).
2. [x] Xcode project via XcodeGen; app builds and runs on the installed iOS 26.4 iPhone 17 simulator (via `-target`; scheme destinations need the iOS 26.5 platform, see ios/README.md).
3. [x] Screens (swipe gestures not yet exercised, only static states shot): feed (vertical topics, horizontal cards, page dots), card (headline above, picture panel fills, paragraph below), opener (question large), guess, more ("Go deeper"), Index sheet, interaction cue pill with the same timing rules as the web.
4. [x] Launch arguments (`--topic`, `--card`) so any screen can be shot headlessly; screenshots into `ios/wireframe/`.
5. [x] `ios/README.md` (how to open, build, regenerate) and a short wireframe note listing what is real vs placeholder.

### Phase 4 blocker: the phone is on iOS 27 (2026-10-24)
Xcode 26.6 cannot connect to an iOS 27 iPhone. Apple's requirements page: **Xcode 27 needs macOS Tahoe 26.6 or later** (it debugs iOS 17+ devices). This Mac is on macOS 26.3.1 and offers macOS Tahoe 26.7.1 (about 7 GB; enough, no need for macOS 27.0.1 at 12 GB).
Plan, owner does the GUI parts: (1) System Settings > General > Software Update > macOS Tahoe 26.7.1, restart; (2) install Xcode 27 (App Store or developer.apple.com/download, free Apple ID is fine); (3) Xcode > Settings > Accounts is already re-signed in; (4) plug the iPhone in, unlock, Trust, Developer Mode on; (5) `cd ios && ./run-device.sh`. The iOS 26.5 simulator download was cancelled (obsoleted by Xcode 27's own platform). Then re-test `xcodegen generate` and a scheme build under Xcode 27 (`xcode-select -s /Applications/Xcode-27.app` if both are installed).
Update (2026-10-24, later): blocker cleared. Mac is on macOS 27.0.1 with Xcode 27.1; phone is paired. `./run-device.sh` builds and installs on the phone; launch is denied until the developer profile is trusted (Settings > General > VPN & Device Management > Apple ID > Trust), then re-run. Script's default device id fixed to the phone's UDID (the old CoreDevice id no longer matched).

## Phase 5 experiment: voice-led topics (2026-10-30, after tester feedback "too much reading")
- **Prototype:** Shazam only, opt-in with the `--voice` launch argument (`EXTRA="--voice" ios/run-device.sh shazam`). One screen, no sideways swipe: the spine paragraph is narrated, picture i plays on beat i, and the caption lights up each word. Code: `ios/Polymath/VoiceTopicView.swift`; the feed swaps it in only when `voice-<id>.json/.m4a` ship in Resources.
- **Narration:** Kokoro-82M (open source, Apache 2.0), voice `af_heart`, rendered offline by `tools/voice/render.py` from `tools/voice/<id>.txt` (one paragraph per beat). Shazam runs 67 s.
- **Why Shazam, not sky-blue:** the sky pictures still say "particles", "bounced" and "40 times", which the approved spine replaced. A voice-over that contradicts the picture would wreck the test.
- **Not built yet:** "Ask a question" (plan: on-device speech recognition, an answer grounded in the topic's `facts.md`, spoken back with Kokoro). Open question for the test: is 67 s too long for a short?
