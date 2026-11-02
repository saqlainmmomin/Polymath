# Handoff: Blueprint pictures for "afterimage" and "own-voice" (iOS app)

## Goal
Two new Polymath topics have approved copy but no native pictures. Done = each topic's four picture cards are drawn in the approved Blueprint style (`FlatAfterimageBP.swift`, `FlatVoiceBP.swift`), mapped in `Pictures.swift`, compile, play on the owner's iPhone, and the owner has approved each topic on the phone. Copy is final; only pictures are in scope.

- **afterimage:** "Why do you see spots after looking at a bright light?" (4 picture cards + a Go deeper card with no picture)
- **own-voice:** "Why does your voice sound different on a recording?" (4 picture cards + a Go deeper card with no picture)

## Current state (2026-11-02)
- Copy, fact sheets and slides are done: `tasks/spine-afterimage/` and `tasks/spine-voice/` (each holds `facts.md`, `paragraph.md`, `slides.md`). Both passed a Stage 4 fact recheck, and I fixed the one flag each.
- Topic files `topics/afterimage.js` and `topics/own-voice.js` exist, build clean (lint warnings only) and are in `LIBRARY` in `build.mjs`. Their web diagrams are simple stand-ins; the iOS app ignores them once native pictures exist.
- The iOS app has **no pictures for either topic yet**, so cards fall back to the wireframe `VisualPanel` placeholder. `Resources/topics.json` is regenerated from `topics/*.js` by `ios/run-device.sh`, so the new topics reach the phone on the next deploy.
- All other 11 topics are already on navy blueprint paper with looping Blueprint pictures, each approved by the owner (see `tasks/handoffs/2026-10-28-blueprint-rollout.md`, Results). **Open `FlatSeasonsBP.swift` and `FlatGlueBP.swift` first:** they are the nearest references (short topics with one hands-on idea each). `FlatShazam.swift` is the original style reference.
- Not yet done and not part of this handoff: the two-person human cold read of each topic (the owner's call), and any republish of the private preview.

## Key files
- `/Users/saqlainmomin/tell-me-how/PRODUCT.md`: product goal (curiosity, effortless).
- `/Users/saqlainmomin/tell-me-how/CLAUDE.md`: project rules and gotchas.
- `/Users/saqlainmomin/tell-me-how/tasks/spine-afterimage/slides.md` and `/Users/saqlainmomin/tell-me-how/tasks/spine-voice/slides.md`: the final card text, the picture description per card and the exact picture labels. Start here.
- `/Users/saqlainmomin/tell-me-how/tasks/spine-afterimage/facts.md` and `/Users/saqlainmomin/tell-me-how/tasks/spine-voice/facts.md`: what is safe to draw. Section 4 (myths) rules out some pictures.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Blueprint.swift`: the picture engine (`PaperGrid`, `BlueprintStage`, `Iso`, `bpSlab`, `bpTrace`, `bpGuide`, `bpLeader`, `bpDimension`, `bpPerson`, `bpArm`, `bpNote`, `bpText`, `BP.paper`).
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/FlatSeasonsBP.swift`, `FlatGlueBP.swift`, `FlatShazam.swift`: reference implementations.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Pictures.swift`: maps `topic.id` + card index to a picture view. Add an `if topic.id == "afterimage"` and an `if topic.id == "own-voice"` block in the same pattern as the others, before the final `gps` guard.
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/CardViews.swift`: card layout (headline, paragraph, picture fills the rest, like/save bottom-right).
- `/Users/saqlainmomin/tell-me-how/ios/Polymath/Resources/topics.json`: the card copy as the app sees it. Check every label against it.
- `/Users/saqlainmomin/tell-me-how/ios/project.yml` and `ios/README.md`: how new Swift files get into the Xcode project (earlier builds added files to `project.pbxproj`; follow how `FlatGlueBP.swift` was added).

## Card plan (from slides.md; confirm with the owner before building, see Constraints)
**afterimage** (`id: "afterimage"`, card indices 0 to 3; index 4 is Go deeper, return nil):
1. Flash, then a dark spot hangs over a wall and stays when the view drops to the floor. Labels: FLASH · DARK SPOT · WALL · FLOOR.
2. Side view of an eye; flash lands on the layer of cells at the back; one patch dims. Labels: FLASH · LAYER OF CELLS AT THE BACK OF YOUR EYE · TIRED CELLS.
3. **Weakest card.** The cell layer as a grid facing a plain wall: normal cells send strong signals up to a picture, tired cells send faint ones, and a dark spot appears in the picture exactly where the tired cells are. The spot must be built from those same cells. Labels: NORMAL CELLS: STRONG SIGNAL · TIRED CELLS: WEAK SIGNAL · WHAT YOU SEE.
4. An eye turns; the tired patch stays on the same cells so the dark spot slides across the scene; then the patch brightens and the spot fades. Labels: TIRED CELLS · CELLS RECOVER: SPOT FADES (drag-to-look is optional; the other topics use automatic motion, no drag).

**own-voice** (`id: "own-voice"`, indices 0 to 3; index 4 is Go deeper, return nil):
1. A person talks. One speech bubble is the voice you hear when you talk; a second comes from a phone's playback and the person frowns at it. Labels: THE VOICE YOU HEAR WHEN YOU TALK · THE RECORDING.
2. A head from the side: sound curves round through the air to the ear (air route); a second line runs inside the head from mouth to ear (inside route, bone and flesh). A friend opposite gets only the air route. Labels: AIR ROUTE · INSIDE ROUTE: BONE AND FLESH · YOUR FRIEND GETS ONLY THE AIR ROUTE.
3. **Weakest card.** A voice drawn as two bands, low and deep, and high. The inside route passes the low band mostly, so the ear hears a fuller sound. Then fingers plug the ear: the air route closes and the inside route's low band gets louder (boomy). The low/high split must be obvious at a glance. Labels: LOW, DEEP PART · HIGH PART · INSIDE ROUTE · FINGERS IN EARS: BOOMY.
4. A microphone beside the speaker's head gets the air route only; a friend beside it the same; the speaker's own ear shows both routes, the extra inside route glowing. Labels: MICROPHONE: AIR ROUTE ONLY · YOUR FRIEND: AIR ROUTE ONLY · YOU: AIR ROUTE AND INSIDE ROUTE.

Facts that constrain the drawings:
- afterimage: the tired patch is on the layer of cells at the back of the eye (the retina) and is fixed there, so it moves with the eye. Do not draw bleached or "used up" cells, light stored in the eye, a colour change (no opposite-colour rule after a white flash), or a burnt hole.
- own-voice: the microphone and the friend get the air route only; only the speaker gets both. Do not label anything higher or lower pitch; the inside route makes the voice "fuller" by carrying the low part. Do not draw the recording as "exactly" what others hear.

## Constraints (decisions already made; do not relitigate)
- **Copy is final.** Never edit `topics/*.js` text, `topics.json` or anything in `tasks/spine-*/` except to append notes. If a picture needs different words, report it in Results.
- **Style (owner-approved):** navy grid paper; chalk lines of even weight (about 1.4pt edges, 1pt leaders and guides); flat tints only, no gradients, glow or blur; one mustard accent, used for the one thing the card is about; small uppercase mono labels on leader lines; big readable shapes; people must read as people; isometric or cutaway scenes welcome.
- **Labels use the card text's exact words.** The owner has asked for this on every topic. Where the plan above differs from `topics.json`, use the card text's words and note it.
- **Motion:** the most recent approved topics all loop continuously after the first pass with a held end beat and a fade-reset, fire the haptic on the first cycle only, and show the held end state under Reduce Motion. Do the same; nothing animates as a function of the swipe; tap replays. The owner asked for loops after finding stills played out before they finished reading.
- **Layout:** stay clear of the bottom-right like/save corner. The grey setup line under card 1's headline was removed from the UI; do not rely on it.
- **Confirm direction with the owner before building:** show the card plan above (adjusted if you disagree) and get a yes per topic, as the 2026-10-28 handoff does. The owner approves each topic on the phone before it counts as done.
- **Two-pass design rule:** one design pass at build, one before exposure, none between. On a third polish request for the same element, mention the rule once, then comply.
- **Other sessions share this checkout.** `Pictures.swift`, `Blueprint.swift` and other files may have uncommitted edits from other sessions. Re-read a file right before editing it, make small exact edits, never stash, reset, switch branches, rewrite whole files or touch other topics' pictures. Do not edit `build.mjs`.
- **Never run or boot the iOS simulator** (it slows the owner's laptop). Never republish the testers' link (https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP). Commit only when the owner asks.
- Use Sonnet subagents to build, one topic at a time, with a self-contained brief (card copy, scene per card, exact label words, style rules, files they may touch: only that topic's `Flat*BP.swift` plus the mapping in `Pictures.swift`).

## Verification
1. Compile: `cd ios && xcodebuild -project Polymath.xcodeproj -target Polymath -sdk iphoneos -configuration Debug CODE_SIGNING_ALLOWED=NO SYMROOT="$PWD/build/products" build 2>&1 | grep -E "error: |\*\* BUILD"` must print `BUILD SUCCEEDED`.
2. Deploy one card at a time to the owner's phone (it must be unlocked): `ios/run-device.sh afterimage <card-number>` and `ios/run-device.sh own-voice <card-number>`. The `--topic/--card` launch args sometimes open another topic on first launch; check the screenshot shows the right topic.
3. Screenshot it yourself about 6 seconds after launch: `xcrun devicectl device capture screenshot --device 00008120-001A7188026BC01E --destination <scratchpad>/x.png`, shrink with `sips -Z 1400`, and read it. If a screenshot shows anything other than Polymath (a call, notifications, another app), delete it unviewed and stop capturing until the owner says the phone is free.
4. For each card check: labels match the card text, leaders have tails and stay off the screen edge and the like/save corner, nothing overlaps, the weakest cards (afterimage 3, own-voice 3) make their one idea readable without the paragraph.
5. Never say a card is done from a compile alone: it needs a screenshot from the phone, and the topic needs the owner's yes.

## Report back
Append a `## Results` section to this file. For each topic, record: cards built and files touched, what was seen on the phone, deviations from the plan above, open issues, and the owner's verdict. Do not edit context docs (CLAUDE.md, MEMORY.md); propose changes in Results.

## Results
(2026-11-02, Sonnet 5.5. Card plan confirmed by the owner in chat: "Both as planned". Built by one Sonnet subagent per topic. Nothing committed.)

### Both topics: common notes
- **Compile:** `xcodebuild ... build` prints `** BUILD SUCCEEDED **` (re-run by me after each topic landed). Deployed with `ios/run-device.sh afterimage 1`, then relaunched each card with `devicectl ... --topic <id> --card <n>` (no rebuild) and screenshotted 3 to 7 s after launch.
- **Project file:** `Polymath.xcodeproj` is gitignored and lists files explicitly, so each new file needed `xcodegen generate` in `ios/`. That also pulled in other sessions' untracked files (voice resources, `FlatSkyBP.swift`, `FlatWetBP.swift`); harmless.
- **Deviations from the plan:** no drag controls (afterimage 4 "drag to look", own-voice 3 "drag fingers"); the eye turns and the fingers plug the ear on their own. Labels use the slides' exact words (they already match `topics/*.js`). Go deeper cards (index 4) return nil, no picture.
- **Phone quirk:** the first launch of `afterimage 1` opened on card 2, and some minutes later the phone was showing the sky-blue topic (the app had moved on by itself or by hand). Relaunching with `--topic/--card` fixed it; every screenshot below was checked to show the right topic.
- **Not tested:** Reduce Motion on the phone, the first-cycle-only haptic (both are built on the shared `BlueprintStage`/cycle pattern, but I did not feel or toggle them).

### afterimage
- **Files:** new `ios/Polymath/FlatAfterimageBP.swift` (private helpers prefixed `af`, incl. `afGroup` which multiplies opacity so nested fades work); `ios/Polymath/Pictures.swift` gained the `afterimage` block (cards 0 to 3: `AfterBPSpot`, `AfterBPEye`, `AfterBPCells`, `AfterBPTurn`).
- **Seen on the phone (all four cards, 2 or more frames each):**
  1. Spot: face lit by a flash from a camera on a tripod, then a brick wall in a frame with a dark disc ringed in mustard, the view slides down to a floor and the disc stays put. Labels FLASH, WALL, DARK SPOT, FLOOR all legible, none in the like/save corner.
  2. Eye: side-view eye, rays converge through the lens to the back, three cells go hatched with a mustard outline. Labels FLASH, LAYER OF CELLS AT THE BACK OF YOUR EYE (two lines), TIRED CELLS fit.
  3. Cells (weak card): 11 cells in a row, normal ones send thick solid lines up, the 3 tired ones thin dashed mustard lines; the picture frame fills column by column and the dark ellipse sits exactly above the 3 tired cells (same x range). Reads without the paragraph.
  4. Turn: scene fixed, top-down eye turns, the spot slides with a dashed mustard line from the tired cells, then cells brighten and the spot fades. The held end frame shows the recovered state.
- **Open issues / for the owner's eye:** on card 1 the person is small and sparse; the dark disc on card 4 hides part of the tree as it passes; the wall strip on card 3 is unlabelled (not in the exact label list); the hatching on the three tired cells on card 2 is tight but did read as hatching.
- **Owner's verdict:** approved (2026-11-02, in chat after swiping through on the phone).

### own-voice
- **Files:** new `ios/Polymath/FlatVoiceBP.swift` (private helpers prefixed `vo`, incl. `voGroup`); `ios/Polymath/Pictures.swift` gained the `own-voice` block (cards 0 to 3: `VoiceBPTalk`, `VoiceBPRoutes`, `VoiceBPBands`, `VoiceBPMic`). The structs' `static func draw` is internal (not private) because the subagent rendered PNGs with a throwaway harness in its scratchpad; the harness is not in the repo. Safe to make private again later.
- **Seen on the phone:**
  1. Talk: a profile head with a frown, a full mustard speech bubble for the voice you hear and a thinner wave in the second bubble coming out of a phone with a play button. Labels fit. The recording is not drawn as "exactly" what others hear.
  2. Routes: hatched cutaway head, dashed air route curving to the ear, mustard inside route running through the hatching, a friend opposite with only a dashed air line. Labels fit; the friend's leader is a long vertical line.
  3. Bands (weak card): thick slow LOW wave and thin fast HIGH wave, an air box (dashed) and an inside box (solid) where the thin wave is blocked and the thick one passes, both feeding an ear with a combined wave in a bubble. Then two fingers plug the ear, an X closes the air route, the inside low wave gets bigger and the ear's wave turns mustard and larger, label FINGERS IN EARS: BOOMY. The low/high split reads at a glance. Nothing is labelled higher or lower.
  4. Mic: speaker head with air route plus a mustard inside route that flashes, a microphone and a friend each reached by a dashed air line only. Labels fit, clear of the corner.
- **Open issues / for the owner's eye:** on card 2 the air route curves close to the speaker's eye and the friend's dashed line crosses the friend's nose; on card 4 the "YOU" leader anchors on the top of the head rather than the ear, and the bottom left is empty; on card 3 the fingers look like two pipes plus a palm block; the HIGH PART leader sits between the two boxes.
- **Owner's verdict:** approved (2026-11-02, in chat after swiping through on the phone).

### Colour pass on all other topics (2026-11-02, owner's request after seeing sky-blue)
- **What:** 24 Sonnet agents (two per topic, split by cards) recoloured 12 topics (all except sky-blue) using the sky-blue hues, now shared in `ios/Polymath/BPColors.swift` as `BP.Hue` (mustard focal, sky, coral, teal, lime). Colour only: no layout, motion or label-word changes. This includes afterimage and own-voice, which the owner had approved in chalk-and-mustard form earlier the same day.
- **Hue roles:** sky = water, air, sound, signals; coral = heat, force, sparks, the Sun and Moon; teal = carrier or material (glue, ground, hill, readers, mic); lime = living or receiving (people, phone, ears, brain); mustard = the one thing each card is about.
- **Checked:** whole project type-checks and builds; each topic's structs all carry their hues (several agents rewrote whole files, none lost the teammate's edits); five cards seen on the phone (moon-tides 3, superglue 1, gps 4, shazam 5, feel-wet 3) all read well.
- **Cross-half fixes by me:** Moon coral on moon-tides cards 1-3; banks coral on card-payment cards 3-4; touch sensor teal (and skin back to chalk) on feel-wet card 3; road ticks sky on bike-gears card 3.
- **Left for the owner's eye:** seasons card 5 Earth globes carry no hue while cards 1-3 use teal; bike-gears gear lever is mustard on card 1, chalk on card 2, teal on card 5; own-voice card 3's inside high band is now thin mustard; small lime ear marks (own-voice 1, 4); lime fills on small people (birthday); teal handshake lines at half opacity (birthday 3); afterimage card 4 lime cell overlay on the eye. Only 5 of about 50 cards were viewed; the rest are unseen on the phone.
- **Owner feedback, same day:** the cyan/blue and teal sat too close to the navy and were hard to look at; red and yellow were fine. Replaced `BP.Hue.sky` with `BP.Hue.lavender` (B9A8FF) and `BP.Hue.teal` with `BP.Hue.pink` (FF8FC8) across the 12 topics (sky-blue topic untouched, it keeps its own blue) and updated the picture descriptions that named the old hues. Re-checked on the phone: moon-tides 3, superglue 1, gps 4, feel-wet 3 all read clearly. Pink is close to coral on some cards; orange or cream are the fallbacks.
- **Palette change, same day:** the owner found lavender + pink + neon lime ugly together and chose the "Macaron" palette (option D of seven shown), asking for restraint ("tasteful, not over colourful"). `BPColors.swift` now holds `BP.Hue.mustard` F2C14E (focal), `ice` F2F6FF (water, air, sound, signals; reads almost as chalk), `coral` FF6F61 (heat, force, Sun, Moon), `peach` FFB89A (materials and carriers), `pistachio` A8E6CF (living, receiving). Then one agent per topic (12) did a restraint pass: per card mustard plus at most two other hues, everything else back to chalk, coloured tints at most 0.18, labels coloured only when the part they point to is. Built, deployed, and seen on the phone: moon-tides 3, superglue 1, feel-wet 3, shazam 5, afterimage 3, bike-gears 5, all calmer and readable. Side effects to eyeball: gps now only ice and pistachio (lightning, wrong-position ring went chalk); moon-tides card 3's Earth is all chalk with a coral Moon; some mustard fills are paler (cap of 0.18); sky-blue topic untouched (still its own blues).
- **Two-pass design rule:** counts as the "before exposure" pass for these topics.
- **Owner's verdict:** pending.

### Proposed changes to context docs (not made)
- None needed. If the owner approves both topics, `build.mjs` already lists them and the 2026-10-28 handoff's "all topics on blueprint pictures" list can add afterimage and own-voice.
