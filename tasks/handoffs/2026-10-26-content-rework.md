# Handoff: rework the remaining 5 topics (copy first, then animations)

You are continuing Tell Me How / Polymath in `~/tell-me-how`, a phone feed of "how things work" topics.
- Topics are data in `topics/*.js`.
- The iOS app is in `ios/`, with native animated pictures in `ios/Polymath/Flat*.swift`.

Three topics are already done in the new style: **gps**, **shazam** and **moon-tides** (commit `4c03cb6`, 2026-10-25). Your job is the other five.

## Read first, in order
1. `CLAUDE.md`: gotchas.
2. `.claude/skills/write-explainer/SKILL.md`: **the copy rules. Use this skill for every topic.** The examples in `examples/` are the bar, and `gps.md` is the one the owner approved.
3. `RECIPE.md`: §3 card anatomy (headline, then text, then picture), §7 visuals, §8 production line.
4. `topics/gps.js`, `topics/shazam.js`, `topics/moon-tides.js`: finished topics in the new style.
5. `ios/Polymath/FlatTides.swift` and `ios/Polymath/FlatShazam.swift`: the native picture pattern.
   - `FlatPicture` + Canvas, with `Kit.chip` labels.
   - Hands-on cards use a `Panel` with a control and a silent demo until the first touch.
   - The routing is in `ios/Polymath/Pictures.swift`.

`tasks/handoff.md` is out of date. Its "2 sentences / 30 words" budget is replaced by the skill: 15-word sentences, at most 7 per card.

## The five topics

| id | Title now | Content cards | Native pictures |
|---|---|---|---|
| car-engine | How does a car engine actually work? | 5 | none (web wireframes) |
| bike-gears | Why does a slower gear make a steep hill easier? | 6 | none |
| ice-floats | Why does ice float on the very water it came from? | 3 | none |
| sky-blue | Why is the sky blue, but red at sunset? | 4 | none |
| card-payment | What happens in the two seconds after you tap your card? | 4 | none |

All five break the new sentence lint in 1–2 places (`./build.sh library`).

## Phase 1: copy (one topic at a time, owner approves each)
1. Read the topic's current file to collect its facts. Its numbers passed an earlier fact check, but re-check anything new.
2. Write the full copy with `write-explainer`, in the skill's output format. Include picture labels and a one-line **Picture** idea per card.
3. **Paste it in chat and stop.** Change no files until the owner approves. Expect a round or two of line-by-line comments.
4. Once approved, write it into `topics/<id>.js`. Hooks go at the end of `text`, the closing line in `takeaway`, and bridges are `{ type: 'bridge', text }`.
5. Run `./build.sh <id>` until lint-clean, then `node tools/export-topics.mjs`.
6. Re-check the titles too. A title must be a plain question and literally true; see the tides lesson below.

Suggested order: ice-floats (smallest), sky-blue, card-payment, bike-gears, car-engine.

## Phase 2: animations (after a topic's copy is approved)
- Build native iOS pictures per card in a new `ios/Polymath/Flat<Name>.swift`, and route them in `Pictures.swift`.
- Bridge cards sit at an index but have no picture.
- Run `cd ios && xcodegen generate` after adding a file.
- Pictures must:
  - fill the panel;
  - use warm, cheerful colours;
  - make sense untouched, with at most one hands-on control per card;
  - use labels in the text's exact words;
  - say what is exaggerated ("BULGE DRAWN MUCH BIGGER");
  - have an `accessibilityLabel` on every view.
- You may use one background subagent per topic. The moon-tides build worked well this way. Give each one:
  - its own `SYMROOT` (`build/agent-<id>`);
  - its own simulator (`xcrun simctl create <id>-agent "iPhone 17"`);
  - a list of the files it owns;
  - one small edit each to `Pictures.swift` and `build.mjs`;
  - instructions: no commits, no phone installs.
- Verify every card yourself from screenshots before telling the owner.

## Commands
- **Simulator build:** `cd ios && xcodebuild -project Polymath.xcodeproj -target Polymath -sdk iphonesimulator -configuration Debug SYMROOT="$PWD/build/products" build`
- **Main simulator:** `A6226E77-4321-425A-A537-3A955E4C32A7`.
  - Skip onboarding: `xcrun simctl spawn <sim> defaults write com.saqlainmomin.polymath profile.onboarded -bool true`.
  - Launch: `xcrun simctl launch <sim> com.saqlainmomin.polymath --topic <id> --card <N>` (N is 1-based, and bridges count).
- **Owner's iPhone:** `cd ios && ./run-device.sh <id> <N>`. The phone must be plugged in and unlocked; if the script says "not available", ask the owner.

## Lessons from the Shazam / GPS / tides rework (owner feedback)
- **Explain the idea, not the interaction.** Never write "drag the slider".
- **Text before picture.** Say what the axes and colours mean before the reader acts.
- **One word, one meaning.** "Landmark", "star" and "dot" as synonyms for "peak" were all rejected. "Stars" put the owner off.
- **Plain titles that are literally true.** "How does the Moon influence waves?" became "How does the Moon move the oceans?", because the Moon makes tides, not waves.
- **Cut a slide that confuses rather than patching it.** The Shazam "live concert" slide was retired after two rewrites.
- **Bridges** (text only, large type) close an idea before the next slide builds on it. They don't count toward the 6.
- **Judge clarity with a cold reader**, never the owner or the writer. Every topic has failed its first fact check.

## Rules
- Commit or push only when the owner asks. History goes straight to `main`.
- Several sessions may edit at once. Touch only your topic's files, plus one small edit each to `LIBRARY` and `Pictures.swift`.
- Never republish the testers' link (https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP) without the owner's OK.

## Open from the last session
- moon-tides slide 6: the owner hasn't decided whether to teach "neap tide". The picture says "SMALLER TIDES" for now.
- None of gps, shazam or moon-tides has had a cold newcomer review in the new style yet.

## Status (2026-10-26, end of first session)
- **ice-floats was dropped** at the owner's call ("not worth explaining") after four copy rounds. It moved to `archive-v3-small/ice-floats.js` and is out of `LIBRARY`.
- **feel-wet replaces it:** "How do you know something is wet?". The copy is approved, cold-read and fact checked. It has web stand-in diagrams in `topics/feel-wet.js` and native pictures in `ios/Polymath/FlatWet.swift`, routed in `Pictures.swift`, with card 4 hands-on. Committed `a53b1e4` on local `main` (not pushed) and installed on the owner's iPhone.
- **Not committed:** `ios/Polymath/Resources/topics.json`. It mixes in another session's uncommitted Shazam/`hook` changes, so commit it after those land. feel-wet's bold lines use the `hook` field, which needs those same changes.
- **Dangling links:** sky-blue and shazam still link to `ice-floats` in their `more` cards. The app drops them quietly; repoint them when those topics are reworked.
- **Next:** sky-blue, then card-payment, bike-gears and car-engine.
- **Owner lessons from this round:**
  - Cut a topic whose honest answer is one line.
  - Every example must be picturable ("10 ml of stone" and "a cupful" failed).
  - The title carries the surprise.
