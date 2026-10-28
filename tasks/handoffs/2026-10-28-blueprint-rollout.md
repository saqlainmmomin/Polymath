# Handoff: roll the blueprint look out to every topic (iOS app)

## Goal
Every topic in the iOS app (`ios/Polymath`) sits on the same navy blueprint grid paper Shazam uses, and then, one topic at a time, each topic's card pictures are redrawn in the approved Blueprint style (or kept hand-drawn where the owner says the sketch works). Done = all 11 topics on grid paper, and each topic's pictures either redone or explicitly kept, each one approved by the owner on their iPhone.

## Current state (2026-10-28)
- **Shazam is the finished reference** (commit `cd18e7a`): five Blueprint cards in `FlatShazam.swift`, approved by the owner. Open it on the phone (`ios/run-device.sh shazam 1`) before designing anything else.
- **Background:** only Shazam is on paper. `Store.shade(_:)` returns `S.paper` for `"shazam"`; every other topic still uses a pastel gradient from `S.gradients`. `FeedView` draws `PaperGrid` behind paper topics and forces dark mode for them (`isPaper`).
- **Pictures for other topics** live in `Flat*.swift` (one file per topic) and are mapped by `Pictures.swift`. Three use the hand-drawn helpers in `Sketch.swift`: Birthday, Glue and Seasons. GPS, Pay, Bike, Sky, Tides and Wet are thin-line scenes drawn for the pastel gradient. `car-engine` has no native pictures and falls back to the wireframe `VisualPanel`.
- Topics (id, cards): car-engine 6, bike-gears 6, feel-wet 5, sky-blue 6, gps 7, card-payment 6, shazam 6, moon-tides 8, birthday 6, seasons 6, superglue 5. Some cards are text-only bridges or the "Go deeper" card, so they have no picture.
- Pictures read their colours from `@Environment(\.stage)` (`StagePalette`: ink, soft, accent). On paper that palette is chalk `#EAF0FF` ink and mustard `#F2C14E` accent. Pictures drawn for pastel gradients use dark ink and will be hard to read on navy until they are redone.

## Key files
- `/Users/saqlainmomin/tell-me-how/PRODUCT.md`: the product goal (curiosity, effortless). Read first.
- `/Users/saqlainmomin/tell-me-how/CLAUDE.md`: project rules and gotchas.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Blueprint.swift`: the picture engine. It holds `PaperGrid` (navy `#0F1E46`, 12pt minor and 48pt major grid, very faint) and `BlueprintStage`, which plays once after the card settles, then rests, replays on tap, honours Reduce Motion and fires an optional haptic. It also has `Iso` projection, `bpSlab`, `bpTrace`, `bpGuide`, `bpLeader`, `bpDimension`, `bpPerson`, `bpArm`, `bpNote`, `bpCode`, `bpText` and `BP.paper` (the opaque fill colour).
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/FlatShazam.swift`: the reference implementation of five Blueprint cards.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Theme.swift`: `S.paper` shade, `S.background`, `S.stage` palettes, gradients.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Store.swift`: `shade(_:)` and `isPaper(_:)` decide which topics are on paper.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/FeedView.swift`: draws the background and forces dark mode on paper topics.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Pictures.swift`: maps topic id and card index to a picture view.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/CardViews.swift`: card layout. Headline and paragraph, then the picture stage fills the rest above the page dots. Like and save sit bottom-right.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Sketch.swift`: hand-drawn helpers, used by Birthday, Glue and Seasons.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Resources/topics.json`: card copy, exported from `topics/*.js` by `tools/export-topics.mjs`. `run-device.sh` re-exports it.
- `/Users/saqlainmomin/tell-me-how/tasks/animation-wow-research.md`: background research on explainer animation.

## Work plan
1. **Paper for everyone.** Put all topics on paper: make `Store.shade` return `S.paper` for every topic, or replace the gradient path. Keep the change small and remove dead gradient code only if nothing uses it. Deploy, then check every topic's cards on the phone. List the pictures that become unreadable on navy; that list is the order of work for step 2.
2. **Confirm direction with the owner before building each topic.** For each topic, show the current pictures on the phone and propose, card by card, whether to redo it in Blueprint (isometric technical drawing, one chalk ink plus mustard accent) or keep it hand-drawn with Sketch recoloured for navy. The owner said some hand-drawn pictures were fine. Get a yes per topic before building.
3. **Build with Sonnet subagents,** one topic at a time (Agent tool, `model: "sonnet"`). Give each subagent a self-contained brief: the card copy, the scene for each card, the exact label words, the style rules below, the files it may touch (only that topic's `Flat*.swift`, plus shared helpers in `Blueprint.swift`), and the compile-only command. Reuse the same subagent with SendMessage for follow-up rounds on the same topic.
4. **Check before showing.** Deploy and take your own screenshots (see Verification). Compare against the brief: overlaps, labels, the like/save corner, readability. Fix what you can see, then show the owner. One topic at a time; the owner approves each.

## Constraints (decisions already made; do not relitigate)
- **Style (approved on Shazam):**
  - Navy grid paper on every card.
  - Chalk lines of even weight (about 1.4pt edges, 1pt leaders and guides).
  - Flat tints only: no gradients, glow or blur.
  - One mustard accent, used for the one thing the card is about.
  - Labels are small uppercase mono on leader lines.
  - Big, readable shapes with tasteful detail.
  - People must read as people.
  - Isometric cutaway scenes are welcome.
- **Labels use the card text's exact words.** Check each label against `topics.json`.
- **Motion:**
  - A picture plays once after its card settles, then rests.
  - Ambient loops are allowed only where the owner approved them; Shazam card 1's sound loop is the only one so far.
  - Nothing animates as a function of the swipe.
  - Tap replays the picture.
  - Reduce Motion shows the end state.
  - Fire one haptic on the key moment.
- **Layout:** keep clear of the bottom-right like/save corner. The current card layout stays as it is.
- **Copy is final:** never edit `topics/*.js` text.
- **Never run or boot the iOS simulator;** it slows the owner's laptop.
  - Compile with: `cd ios && xcodebuild -project Polymath.xcodeproj -target Polymath -sdk iphoneos -configuration Debug CODE_SIGNING_ALLOWED=NO SYMROOT="$PWD/build/products" build 2>&1 | grep -E "error: |\*\* BUILD"`.
  - Install with `ios/run-device.sh <topic-id> <card-number>`; the phone must be unlocked.
- **The two-pass design rule applies:** if the owner asks for a third polish round on the same element, mention it once, then comply.
- **Git hygiene:**
  - Commit only when the owner asks.
  - Other sessions may share this checkout, so never stash, reset or switch branches.
  - Never republish the testers' artifact link.

## Verification
- After each deploy, screenshot the phone yourself instead of asking the owner. Wait about 6 s after launch so the picture has finished:
  `xcrun devicectl device capture screenshot --device 00008120-001A7188026BC01E --destination <scratchpad>/x.png`
  Then shrink it with `sips -Z 1400` and read it.
- If a screenshot shows anything other than Polymath (a call, notifications, another app), delete it unviewed and stop capturing until the owner says the phone is free.
- **Launching straight onto a card must draw it.** This bug is fixed in `BlueprintStage`. Older `*Stage` shells in other `Flat*.swift` files may have the same frozen-first-card bug, so give them the same `paused: … || start == nil` fix.
- Every topic must compile and deploy, and the owner must have seen it on the phone, before it is called done.

## Report back
Append a `## Results` section to this file. For each topic, record what was redone or kept, the owner's verdict, and open issues.
