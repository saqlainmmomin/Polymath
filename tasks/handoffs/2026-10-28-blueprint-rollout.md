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
- **On hold until their copy rewrite lands (owner, 2026-10-28):** moon-tides, bike-gears, card-payment, gps, feel-wet and sky-blue are being rewritten spine-first (`tasks/handoffs/2026-10-28-spine-rewrite.md`). Their titles, headlines, and card count and order will change, and `Pictures.swift` maps pictures by card index. Don't draw pictures for them, and don't touch `topics/<id>.js` or `tasks/spine-*/` for them. Pick a topic up once its row appears in that handoff's `## Results` table. Fine to do now: shazam, car-engine, superglue, birthday, seasons, shared `Blueprint.swift` work, and the paper background.
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

## Results

### Step 1: paper for everyone (done, compiled and deployed, 2026-10-28)
- `Store.shade(_:)` now returns `S.paper` for every topic, so all 11 topics get the navy `PaperGrid` and forced dark mode. One-line change in `Store.swift`. The `shades` dictionary and `S.gradients` are now unused; left in place (not removed) in case the owner wants a fallback.
- Compiles (`BUILD SUCCEEDED`). Deployed card 1 of each topic to the phone with `run-device.sh` and screenshotted.
- **Phone was not free for one capture:** the feel-wet screenshot showed a chat app, not Polymath. It was deleted and I stopped capturing. **feel-wet card 1 was not checked.** Per the handoff, no further screenshots until the owner says the phone is free.
- Also noticed: `run-device.sh gps 2` opened the glue topic card 1 (the `--topic/--card` launch args may not always take effect on first launch; not investigated).

### Readability after step 1 (card 1 of each topic)
Everything is legible; nothing is broken. But no non-Shazam picture is blueprint-styled yet. Order of work for step 2, most off-style first:
1. **car-engine** — no native pictures; shows the wireframe `VisualPanel` placeholder ("DIAGRAM PICTURE") floating on navy.
2. **sky-blue, gps, card-payment, moon-tides, bike-gears** — full-bleed pastel scenes (blue sky, purple night, cream shop, etc.) that fight the navy grid. Biggest style clash, all need redoing or a recolour.
3. **birthday, seasons, superglue** — hand-drawn Sketch pictures on a cream panel. Readable (dark ink on cream) and look like a deliberate card, but they are not recoloured for navy; owner to decide keep vs redo.
4. **feel-wet** — unchecked (see above).
5. **shazam** — done, reference.

### Steps 2–4: not started
Step 2 needs the owner's per-topic yes (redo in Blueprint vs keep hand-drawn) before any subagent builds. No `Flat*.swift` files were touched. Owner verdicts: none yet.

### Open questions for the owner
- Which topic first? Suggest car-engine (no pictures at all) or a pastel one such as sky-blue.
- For birthday, seasons and superglue: keep hand-drawn on cream panels, or recolour Sketch for navy?

### Hold (from the owner, 2026-10-28)
No picture work for moon-tides, bike-gears, card-payment, gps, feel-wet and sky-blue until their spine-first copy rewrite lands (`tasks/handoffs/2026-10-28-spine-rewrite.md`). Resume each topic once its row appears in that file's Results table. Still fine: shazam, car-engine, superglue, birthday, seasons. Paper-for-everyone stays.
Status: car-engine build is in progress (Sonnet subagent); not yet compiled, deployed or approved.

### car-engine (built, awaiting owner verdict, 2026-10-28)
- Redone in Blueprint: `FlatCarEngine.swift` (5 cards, shared `carEngine` cylinder helper), mapped in `Pictures.swift`; card 6 "Go deeper" has no picture. `project.pbxproj` has the new file. Compiles.
- Deployed and screenshotted cards 1-5. Cards 1-4 read well. Card 5 "CYLINDERS" label was clipped at the left edge; fixed by moving the leader (elbow x 30, tail 0). The fix compiles but is **not yet seen on the phone** (phone locked on redeploy).
- Deviations from the approved plan: front-on cutaway with slight depth, not true isometric; card 1 engine has two cylinders; added labels BIKE PEDAL (card 2) and HEAVY WHEEL (card 5); card 3 stroke names are plain text under each cylinder.
- Owner verdict: pending. Not committed.
- Card 5 CYLINDERS label re-checked on the phone: clear of the left edge and of its leader (elbow x 26, tail 10). All five cards now seen by me; awaiting owner verdict.
- Loops (owner request: "keep things running", ambient loops approved for car-engine only): cards 1-5 now run continuously after the first pass; card 2 pedal turns full circles with the shaft. Redeployed; stills of all five show parts mid-motion (pistons, pedal, flywheel at new positions) and labels clear. Motion itself not judged by me; owner to watch. Possible shimmer at graph edge on card 5. Uncommitted.
- **car-engine: APPROVED by the owner (2026-10-28), looping version.** Open issues: none. Uncommitted.

### superglue (built, awaiting owner verdict, 2026-10-28)
- Redone in Blueprint: `FlatGlueBP.swift` (4 cards: GlueBPFast, GlueBPWater, GlueBPFilm, GlueBPCap) mapped in `Pictures.swift`; card 5 none. Old hand-drawn `FlatGlue.swift` left in place, now unused. Play once then rest; auto cap-on/cap-off on card 4 (no drag). Compiles.
- Seen on the phone, all four cards. Fixed: leader lines touching the first letter of labels on cards 1 and 3 (added horizontal tails). Cards 2 and 4 clean.
- Deviations: card 1 labels are the plan's own wording (not verbatim from topics.json, which has "Runny"/"Hard"/"In the tube"/"On your finger"); card 2 SCHOOL GLUE/SUPERGLUE are plain headings; card 3 uses WATER FILM (card copy says "Film of water").
- Owner verdict: pending. Uncommitted.
- superglue loops (owner: "animation has already played out by the time I read; stills don't look good"; ambient loops approved for superglue): all four cards now loop via `glCycle` (3.9-5.2 s cycles with a held end beat and fade-reset); haptic first cycle only; Reduce Motion shows the held end state. Compiles; not yet seen on the phone. Uncommitted.
- superglue loops redeployed; stills of all four caught different phases (card 1 glue surface tilted mid-slosh, card 2 reset round with fresh runny drops, card 3 new drop falling, card 4 cap off with hardened tip), labels clear. Motion judged by owner; verdict pending. Uncommitted.
- **superglue: APPROVED by the owner (2026-10-28), looping version.** Open issues: none. Uncommitted.

### birthday (built, awaiting owner verdict, 2026-10-28)
- Redone in Blueprint with loops on all five cards: `FlatBirthdayBP.swift` (BirthBPRoom, BirthBPYours, BirthBPPairs, BirthBPRooms, BirthBPCurve), mapped in `Pictures.swift`; card 6 none. Old `FlatBirthday.swift` left, unused. Card 5 uses an automatic arrival up to 57 (no drag). Compiles.
- Seen on the phone, all five cards: labels clear of edges and the like/save corner, leaders have tails, no fixes needed. Card 5's gap in the room's left wall is a deliberate door.
- Deviations: small custom people (`bbMini`) for crowds; card 4 calendars are mini calendars on dealt rooms, tally is a fixed 12-of-24; 253 chalk handshake lines are faint by design.
- Concern for owner: the tiny hatted people can read as bottles or pins rather than people (cards 1 and 5). Left as built.
- Owner verdict: pending. Uncommitted.
- **birthday: APPROVED by the owner (2026-10-28), looping version; tiny people kept as built.** Open issues: none. Uncommitted.

### seasons (built, awaiting owner verdict, 2026-10-28)
- Redone in Blueprint with loops on all five: `FlatSeasonsBP.swift` (SeasonsBPFar, Steps, Lean, Torch, Day), mapped in `Pictures.swift`; card 6 none. Old `FlatSeasons.swift` left, unused. Card 4 torch tilts automatically (no drag). Compiles.
- Seen on the phone, all five cards (a locked-phone screenshot of card 1 was deleted unviewed and retaken). Labels clear, nothing needed fixing.
- Deviations: card 1 orbit is exaggerated (Sun off-centre, ~100 vs 124 pt) with no scale note, while card 2 says the real difference is about 3%; card 2 adds "JANUARY: 100 STEPS", "JULY: 103 STEPS", "SAME DISTANCE"; card 5 adds LONG DAY / SHORT DAY.
- Owner verdict: pending. Uncommitted.

### Setup line removed (owner, relaying Vishwajeet's feedback, 2026-10-28)
The grey "setup" line under card 1's headline (the card's own title) looked odd to a viewer; removed from the UI in `CardViews.swift` (`Lead` no longer takes or draws `setup`). Copy in `topics/*.js` and `topics.json` untouched. Compiles; not yet seen on the phone. Uncommitted.

### moon-tides (built, awaiting owner verdict, 2026-10-28)
- Hold lifted (rewrite row for moon-tides is in `2026-10-28-spine-rewrite.md`). Redone in Blueprint with loops on all five new cards: `FlatTidesBP.swift` (TidesBPBeach, Pull, Bulges, Turn, Later); `Pictures.swift` moon-tides block remapped to the new 5-card order (index 5 "Go deeper" now returns nil; old Sun/Coast mapping removed). Old `FlatTides.swift` left, unused. Compiles.
- Seen on the phone, all five cards (one frame each, at different loop phases; card 2 caught with its arrows retracted, card 3 at the start of its runner pull, so those two end beats were not seen by me). Labels clear, nothing needed fixing.
- Deviations: card 2 arrows point toward the Moon from each of near sea/ground/far sea; card 3 has an unlabelled magnet and dashed guide; card 4 Moon unlabelled; card 5 "ABOUT 50 EXTRA MINUTES" on three lines; cards 3-5 fade the whole picture out and in between rounds.
- Owner verdict: pending. Uncommitted.
- **moon-tides: APPROVED by the owner (2026-10-28), looping version.** Open issues: none. Uncommitted.
- Headline-to-paragraph gap (`Lead` bottom padding in `CardViews.swift`) set to 8pt at the owner's request (was 12pt, added after the grey setup line was removed). Compiles; not yet deployed.

### bike-gears (built, awaiting owner verdict, 2026-10-28)
- Hold lifted (rewrite row in `2026-10-28-spine-rewrite.md`). Redone in Blueprint with loops on all five: `FlatBikeBP.swift` (BikeBPHill, Rings, Carry, Walk, Flat) with a shared `bgBike` helper; `Pictures.swift` bike-gears block remapped; old `FlatBike.swift` left, unused. Compiles.
- Seen on the phone, all five cards (one frame each; card 3 caught at the very start of its loop, so its distances were not seen by me). Cards 1, 2 and 4 read well. Card 5: the BIGGER BACK RING leader ran a long diagonal to the far left edge (elbow x 4); moved elbows to x 34 on the BIGGER and SMALLER BACK RING leaders (FlatBikeBP.swift lines ~744-745). Fix compiles but is NOT yet seen: phone locked on redeploy.
- Deviations: card 3 uses two stacked lanes from one start line (distances don't fit one lane); card 4 uses two separate hills sharing one height line; lever drawn 2-3x for legibility; state labels (BIGGER/SMALLER BACK RING, ONE PEDAL TURN, distances) redraw each loop.
- Owner verdict: pending. Uncommitted.
- bike-gears recheck (2026-10-29): card 3 distances seen and read well (SHORTER WAY vs a roughly 2x FARTHER, mustard bar). Card 5 leaders: elbow x 34 made BIGGER BACK RING run into the rider's helmet; set to x 10 (text x ~24-141), seen clear of the rider. SMALLER BACK RING label (appears later in the loop) was not seen after the change. Leader still crosses the rear wheel as a hairline. Owner verdict: pending. Uncommitted.
- **bike-gears: APPROVED by the owner (2026-10-29), looping version.** Open issues: none. Uncommitted.

### card-payment (built, awaiting owner verdict, 2026-10-29)
- Hold lifted (rewrite row in `2026-10-28-spine-rewrite.md`). Redone in Blueprint with loops on all four new cards: `FlatPayBP.swift` (PayBPTap, Hops, Promise, Totals); `Pictures.swift` card-payment block remapped (indices 0-3; "Go deeper" gets none). Old `FlatPay.swift` left, unused. Compiles.
- Seen on the phone, all four cards (one frame each at different loop phases: card 2 caught near the start, before the message hops). Labels clear of edges and the like/save corner; nothing needed fixing.
- Deviations: card 2 labels are plain text with a stub line (four labels did not fit as leaders); card 3's yes is a tick pill and the gap is an unlabelled dashed line; card 1 has a dashed envelope outline at the message's resting place; card 4 TOTALS leader does not follow the moving totals. No brand names, figures or day counts anywhere.
- Owner verdict: pending. Uncommitted.
- **card-payment: APPROVED by the owner (2026-10-30), looping version.** Open issues: none. Uncommitted.

### gps (built, awaiting owner verdict, 2026-10-30)
- Hold lifted (rewrite row in `2026-10-28-spine-rewrite.md`). Redone in Blueprint with loops on all five new cards: `FlatGpsBP.swift` (GpBPSilent, Send, Gap, Spots, Clock); `Pictures.swift` gps block remapped (indices 0-4; "Go deeper" none). Old `FlatGPS.swift` left, unused. Compiles.
- Seen on the phone: cards 2-5 (one frame each, early in their loops). **Card 1 not seen:** its screenshot showed the home screen (app had backgrounded); deleted unviewed, capturing stopped.
- Critique with the Anatomy craft rules (read as text only, nothing installed; rules that conflict with the Blueprint style, such as no leaders/labels/hatching/dashes, were skipped): card 4 reads well (one accent on the Earth spot, rings really meet at the two spots, so numbers and drawing agree; satellites are drawn collinear, which a reader may take as required); cards 2, 3, 5 were caught early so their story beats are not judged; card 2's figure fills little of the vertical space (empty above and below).
- Deviations (subagent): card 4 satellites collinear; card 3 uses two timelines with an exaggerated 0.07 s gap; card 5 uses a ring round the phone as "your position"; card 1 has no explicit "nothing goes back up" mark.
- Owner verdict: pending. Uncommitted.
- gps recheck (2026-10-30): captured cards 1, 2, 3 and 5 at three points each, later in their loops (card 1's earlier capture of the home screen was deleted). All four read well; labels clear, no overlaps with the like/save corner, Anatomy craft rules (fill, one idea per accent, lines land on something, drawing matches copy) satisfied. No fixes made. Notes: card 3's lower SENT / ARRIVED timeline sits near the bottom of the picture area; card 5 mid-loop frame shows the phone and the offset target ring clearly. Owner verdict: pending. Uncommitted.
- **gps: APPROVED by the owner (2026-10-30), looping version.** Open issues: none. Uncommitted.
